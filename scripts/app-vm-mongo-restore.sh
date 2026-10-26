#!/usr/bin/env bash
set -euo pipefail

# Restores a MongoDB dump into the MongoDB container running on the application VM.
#
# The existing scripts/mongodb-vm-restore.sh assumes mongosh/mongorestore installed
# on the host and a database reachable at 127.0.0.1:27017. Neither holds once
# MongoDB runs as a Compose service with no published port, so this script streams
# the archive into mongorestore executed *inside* the container via docker exec.
#
# Port 27017 is never published on the host and never opened in the security group.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

TERRAFORM_DIR="${APP_VM_TERRAFORM_DIR:-${REPO_ROOT}/deploy/terraform/app-vm}"
DUMP_DIR="${MONGODB_VM_DUMP_DIR:-${REPO_ROOT}/dump}"
DUMP_FILE="${1:-${MONGODB_VM_DUMP_FILE:-${DUMP_DIR}/read-tracker-mongodb.archive.gz}}"

TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"
SSH_BIN="${SSH_BIN:-ssh}"

SSH_USER="${APP_VM_SSH_USER:-ubuntu}"
SSH_PORT="${APP_VM_SSH_PORT:-22}"
SSH_CONNECT_TIMEOUT="${APP_VM_SSH_CONNECT_TIMEOUT:-10}"

REMOTE_COMPOSE_DIR="${APP_VM_REMOTE_ROOT:-/srv/read-tracker}/compose"
MONGO_SERVICE="${APP_VM_MONGO_SERVICE:-mongodb}"
MONGO_USER="${APP_VM_MONGO_USER:-readtracker}"
MONGO_DB_NAME="${APP_VM_MONGO_DB_NAME:-read_tracker}"

log() {
  printf '[app-vm-mongo-restore] %s\n' "$*"
}

fail() {
  printf '[app-vm-mongo-restore] ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command '$1' not found"
}

ssh_target() {
  printf '%s@%s' "$SSH_USER" "$(resolve_ssh_host)"
}

ssh_options() {
  local options=(
    -p "$SSH_PORT"
    -o BatchMode=yes
    -o ConnectTimeout="$SSH_CONNECT_TIMEOUT"
    -o StrictHostKeyChecking=accept-new
  )

  if [[ -n "${APP_VM_SSH_KEY_PATH:-}" ]]; then
    options+=(-i "$APP_VM_SSH_KEY_PATH")
  fi

  printf '%s\n' "${options[@]}"
}

ssh_run() {
  local options=()
  local option

  while IFS= read -r option; do
    options+=("$option")
  done < <(ssh_options)

  "$SSH_BIN" "${options[@]}" "$(ssh_target)" "$@"
}

resolve_ssh_host() {
  local public_ip

  if [[ -n "${APP_VM_PUBLIC_IP:-}" ]]; then
    printf '%s' "$APP_VM_PUBLIC_IP"
    return 0
  fi

  public_ip="$("$TERRAFORM_BIN" -chdir="$TERRAFORM_DIR" output -raw public_ip 2>/dev/null)" || true
  [[ -n "$public_ip" ]] || fail "Terraform output 'public_ip' is unavailable in ${TERRAFORM_DIR}. Run 'make tf-app-vm-apply' first."

  printf '%s' "$public_ip"
}

# The password is read on the VM from the deployed .env rather than passed on the
# command line, so it never appears in this host's process list or shell history.
container_restore_command() {
  cat <<EOF
set -euo pipefail
cd $(printf '%q' "$REMOTE_COMPOSE_DIR")
MONGO_PASSWORD="\$(sed -nE 's|^MONGO_PASSWORD=(.*)\$|\1|p' .env | head -n 1)"
[ -n "\$MONGO_PASSWORD" ] || { echo "MONGO_PASSWORD not found in .env" >&2; exit 1; }
URI="mongodb://${MONGO_USER}:\$MONGO_PASSWORD@127.0.0.1:27017/${MONGO_DB_NAME}?authSource=admin"
docker compose -f docker-compose.prod.yml exec -T $(printf '%q' "$MONGO_SERVICE") \
  mongorestore --uri "\$URI" --nsInclude $(printf '%q' "${MONGO_DB_NAME}.*") --drop --archive --gzip
EOF
}

main() {
  require_command "$TERRAFORM_BIN"
  require_command "$SSH_BIN"

  [[ -f "$DUMP_FILE" ]] || fail "Dump file '${DUMP_FILE}' not found. Pass the path as the first argument or set MONGODB_VM_DUMP_FILE."

  log "Restoring ${DUMP_FILE} into the '${MONGO_SERVICE}' container on $(resolve_ssh_host)..."

  if ssh_run "$(container_restore_command)" < "$DUMP_FILE"; then
    log "MongoDB restore completed successfully."
    exit 0
  fi

  fail "MongoDB restore failed. Inspect: ssh $(ssh_target) \"cd ${REMOTE_COMPOSE_DIR} && docker compose logs ${MONGO_SERVICE}\""
}

main "$@"
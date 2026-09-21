#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

TERRAFORM_DIR="${MONGODB_VM_TERRAFORM_DIR:-${REPO_ROOT}/deploy/terraform/mongodbvm}"
DUMP_DIR="${MONGODB_VM_DUMP_DIR:-${REPO_ROOT}/dump}"
DUMP_FILE="${MONGODB_VM_DUMP_FILE:-${DUMP_DIR}/read-tracker-mongodb.archive.gz}"
TFVARS_FILE="${MONGODB_VM_TFVARS_FILE:-${TERRAFORM_DIR}/terraform.tfvars}"

TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"
SSH_BIN="${SSH_BIN:-ssh}"
SSH_KEYGEN_BIN="${SSH_KEYGEN_BIN:-ssh-keygen}"
SSH_USER="${MONGODB_VM_SSH_USER:-ubuntu}"
SSH_PORT="${MONGODB_VM_SSH_PORT:-22}"
SSH_CONNECT_TIMEOUT="${MONGODB_VM_SSH_CONNECT_TIMEOUT:-10}"
DEFAULT_SSH_HOST="${MONGODB_VM_PUBLIC_IP:-169.150.1.49}"
RESOLVED_SSH_HOST=""
SSH_KNOWN_HOSTS_FILE="${MONGODB_VM_SSH_KNOWN_HOSTS_FILE:-${HOME}/.ssh/known_hosts}"

DEFAULT_MONGO_HOST="127.0.0.1"
MONGO_PORT="${MONGODB_VM_PORT:-27017}"
MONGO_DB_NAME="${MONGODB_VM_DB_NAME:-read_tracker}"
MONGO_USER="${MONGODB_VM_USER:-readtracker}"

WAIT_RETRIES="${MONGODB_VM_WAIT_RETRIES:-60}"
WAIT_SECONDS="${MONGODB_VM_WAIT_SECONDS:-5}"

log() {
  printf '[mongodb-vm] %s\n' "$*"
}

fail() {
  printf '[mongodb-vm] ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command '$1' not found"
}

ensure_dump_dir() {
  mkdir -p "$DUMP_DIR"
}

shell_quote() {
  printf '%q' "$1"
}

terraform_output_optional() {
  local output_name="$1"

  if [[ -n "${MONGODB_VM_PUBLIC_IP:-}" && "$output_name" == "public_ip" ]]; then
    printf '%s' "$MONGODB_VM_PUBLIC_IP"
    return 0
  fi

  if [[ -n "${MONGODB_VM_PRIVATE_IP:-}" && "$output_name" == "private_ip" ]]; then
    printf '%s' "$MONGODB_VM_PRIVATE_IP"
    return 0
  fi

  "$TERRAFORM_BIN" -chdir="$TERRAFORM_DIR" output -raw "$output_name" 2>/dev/null
}

terraform_output_required() {
  local output_name="$1"
  local value

  value="$(terraform_output_optional "$output_name")" || true
  [[ -n "$value" ]] || fail "Terraform output '$output_name' is unavailable in ${TERRAFORM_DIR}"

  printf '%s' "$value"
}

vm_is_provisioned() {
  local private_ip

  private_ip="$(terraform_output_optional private_ip)" || true
  [[ -n "$private_ip" ]]
}

tfvars_value() {
  local key="$1"

  [[ -f "$TFVARS_FILE" ]] || return 1

  sed -nE "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*\"(.*)\"[[:space:]]*$/\1/p" "$TFVARS_FILE" | head -n 1
}

mongo_password() {
  local value

  if [[ -n "${MONGODB_VM_MONGO_PASSWORD:-}" ]]; then
    printf '%s' "$MONGODB_VM_MONGO_PASSWORD"
    return 0
  fi

  value="$(tfvars_value mongo_password)" || true
  [[ -n "$value" ]] || fail "MongoDB password not found. Set MONGODB_VM_MONGO_PASSWORD or configure ${TFVARS_FILE}"

  printf '%s' "$value"
}

resolve_mongo_host() {
  local terraform_private_ip

  if [[ -n "${MONGODB_VM_HOST:-}" ]]; then
    printf '%s' "$MONGODB_VM_HOST"
    return 0
  fi

  terraform_private_ip="$(terraform_output_optional private_ip)" || true
  if [[ -n "$terraform_private_ip" ]]; then
    printf '%s' "$terraform_private_ip"
    return 0
  fi

  printf '%s' "$DEFAULT_MONGO_HOST"
}

mongo_uri() {
  local password
  password="$(mongo_password)"

  printf 'mongodb://%s:%s@%s:%s/%s?authSource=admin' \
    "$MONGO_USER" \
    "$password" \
    "$(resolve_mongo_host)" \
    "$MONGO_PORT" \
    "$MONGO_DB_NAME"
}

resolve_ssh_host() {
  local terraform_public_ip

  if [[ -n "$RESOLVED_SSH_HOST" ]]; then
    printf '%s' "$RESOLVED_SSH_HOST"
    return 0
  fi

  if [[ -n "${MONGODB_VM_SSH_HOST:-}" ]]; then
    RESOLVED_SSH_HOST="$MONGODB_VM_SSH_HOST"
    printf '%s' "$RESOLVED_SSH_HOST"
    return 0
  fi

  terraform_public_ip="$(terraform_output_optional public_ip)" || true
  if [[ -n "$terraform_public_ip" ]]; then
    RESOLVED_SSH_HOST="$terraform_public_ip"
    printf '%s' "$RESOLVED_SSH_HOST"
    return 0
  fi

  RESOLVED_SSH_HOST="$DEFAULT_SSH_HOST"
  printf '%s' "$RESOLVED_SSH_HOST"
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

  if [[ -n "${MONGODB_VM_SSH_KEY_PATH:-}" ]]; then
    options+=(-i "$MONGODB_VM_SSH_KEY_PATH")
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

known_host_mismatch_detected() {
  local stderr_file="$1"

  grep -q "REMOTE HOST IDENTIFICATION HAS CHANGED" "$stderr_file"
}

repair_known_host() {
  local host
  host="$(resolve_ssh_host)"

  [[ -f "$SSH_KNOWN_HOSTS_FILE" ]] || return 0

  require_command "$SSH_KEYGEN_BIN"

  log "Detected stale SSH host key for ${host}; refreshing ${SSH_KNOWN_HOSTS_FILE}..."
  "$SSH_KEYGEN_BIN" -f "$SSH_KNOWN_HOSTS_FILE" -R "$host" >/dev/null 2>&1 || true
  "$SSH_KEYGEN_BIN" -f "$SSH_KNOWN_HOSTS_FILE" -R "[$host]:$SSH_PORT" >/dev/null 2>&1 || true
}

wait_for_ssh() {
  local attempt
  local stderr_file

  stderr_file="$(mktemp)"

  for attempt in $(seq 1 "$WAIT_RETRIES"); do
    if ssh_run true >/dev/null 2>"$stderr_file"; then
      rm -f "$stderr_file"
      return 0
    fi

    if known_host_mismatch_detected "$stderr_file"; then
      repair_known_host
    fi

    log "Waiting for SSH on MongoDB VM (${attempt}/${WAIT_RETRIES})..."
    sleep "$WAIT_SECONDS"
  done

  rm -f "$stderr_file"
  fail "Unable to reach MongoDB VM over SSH"
}

wait_for_mongodb() {
  local attempt
  local uri
  local command

  uri="$(shell_quote "$(mongo_uri)")"
  command="mongosh --quiet ${uri} --eval 'db.runCommand({ ping: 1 })'"

  for attempt in $(seq 1 "$WAIT_RETRIES"); do
    if ssh_run "$command" >/dev/null 2>&1; then
      return 0
    fi

    log "Waiting for MongoDB readiness on VM (${attempt}/${WAIT_RETRIES})..."
    sleep "$WAIT_SECONDS"
  done

  fail "MongoDB did not become ready on the VM"
}

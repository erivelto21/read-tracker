#!/usr/bin/env bash
set -euo pipefail

# Delivers configuration and secrets to the application VM and starts the
# production Compose workload.
#
# Phase 2 of the deployment: Terraform provisions the VM without any secret,
# and this script supplies the configuration afterwards. That keeps credentials
# out of Terraform state and lets a rotated secret be applied without recreating
# the VM.
#
# Follows the conventions of scripts/mongodb-vm-common.sh (logging helpers, .env
# sourcing, terraform output lookups) but operates only on deploy/terraform/app-vm.

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
COMPOSE_DIR="${APP_VM_COMPOSE_DIR:-${REPO_ROOT}/deploy/compose}"
SECRET_FILE="${APP_VM_SECRET_FILE:-${COMPOSE_DIR}/.env.secret.yaml}"

TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"
SSH_BIN="${SSH_BIN:-ssh}"
SCP_BIN="${SCP_BIN:-scp}"
SOPS_BIN="${SOPS_BIN:-sops}"

SSH_USER="${APP_VM_SSH_USER:-ubuntu}"
SSH_PORT="${APP_VM_SSH_PORT:-22}"
SSH_CONNECT_TIMEOUT="${APP_VM_SSH_CONNECT_TIMEOUT:-10}"

REMOTE_ROOT="${APP_VM_REMOTE_ROOT:-/srv/read-tracker}"
REMOTE_COMPOSE_DIR="${REMOTE_ROOT}/compose"

HEALTH_RETRIES="${APP_VM_HEALTH_RETRIES:-30}"
HEALTH_SECONDS="${APP_VM_HEALTH_SECONDS:-5}"

log() {
  printf '[app-vm] %s\n' "$*"
}

fail() {
  printf '[app-vm] ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command '$1' not found"
}

# ── Local workspace ───────────────────────────────────────────────────────────
# Secrets are decrypted into a temporary directory that is removed on exit, so
# plaintext never lands in a tracked file.
WORK_DIR=""

cleanup() {
  if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
    rm -rf "$WORK_DIR"
  fi
}

trap cleanup EXIT

make_work_dir() {
  WORK_DIR="$(mktemp -d)"
  chmod 700 "$WORK_DIR"
}

# ── Remote access ─────────────────────────────────────────────────────────────
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

scp_run() {
  local options=(-P "$SSH_PORT" -o BatchMode=yes -o ConnectTimeout="$SSH_CONNECT_TIMEOUT" -o StrictHostKeyChecking=accept-new)

  if [[ -n "${APP_VM_SSH_KEY_PATH:-}" ]]; then
    options+=(-i "$APP_VM_SSH_KEY_PATH")
  fi

  "$SCP_BIN" "${options[@]}" "$@"
}

# ── Terraform outputs ─────────────────────────────────────────────────────────
terraform_output_optional() {
  local output_name="$1"

  if [[ -n "${APP_VM_PUBLIC_IP:-}" && "$output_name" == "public_ip" ]]; then
    printf '%s' "$APP_VM_PUBLIC_IP"
    return 0
  fi

  "$TERRAFORM_BIN" -chdir="$TERRAFORM_DIR" output -raw "$output_name" 2>/dev/null
}

terraform_output_required() {
  local output_name="$1"
  local value

  value="$(terraform_output_optional "$output_name")" || true
  [[ -n "$value" ]] || fail "Terraform output '$output_name' is unavailable in ${TERRAFORM_DIR}. Run 'make tf-app-vm-apply' first."

  printf '%s' "$value"
}

resolve_ssh_host() {
  local public_ip

  public_ip="$(terraform_output_required public_ip)"
  printf '%s' "$public_ip"
}

wait_for_ssh() {
  local attempt

  log "Waiting for SSH on $(resolve_ssh_host)..."
  for attempt in $(seq 1 "$HEALTH_RETRIES"); do
    if ssh_run true >/dev/null 2>&1; then
      return 0
    fi
    sleep "$HEALTH_SECONDS"
  done

  fail "SSH did not become available on $(resolve_ssh_host)"
}

wait_for_docker() {
  local attempt

  log "Waiting for Docker on the VM..."
  for attempt in $(seq 1 "$HEALTH_RETRIES"); do
    if ssh_run 'command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1'; then
      return 0
    fi
    sleep "$HEALTH_SECONDS"
  done

  fail "Docker did not become ready on the VM; check /var/log/cloud-init-app.log"
}

# ── Secret material ───────────────────────────────────────────────────────────
# sops emits dotenv directly, which avoids hand-parsing YAML for values that may
# contain shell metacharacters.
load_secrets() {
  [[ -f "$SECRET_FILE" ]] || fail "Secret file '${SECRET_FILE}' not found. Create and encrypt it with: sops ${SECRET_FILE}"

  local secrets_file="${WORK_DIR}/secrets.env"
  "$SOPS_BIN" --decrypt --output-type dotenv "$SECRET_FILE" > "$secrets_file" \
    || fail "Failed to decrypt ${SECRET_FILE} with SOPS; is the age key available?"

  chmod 600 "$secrets_file"
  # shellcheck disable=SC1090
  set -a
  source "$secrets_file"
  set +a

  [[ -n "${MONGO_PASSWORD:-}" ]] || fail "MONGO_PASSWORD is missing from ${SECRET_FILE}"
  [[ -n "${MONGO_ROOT_PASSWORD:-}" ]] || fail "MONGO_ROOT_PASSWORD is missing from ${SECRET_FILE}"

  # Accept both spellings so the existing key name in the secret file keeps working.
  NGINX_USER="${NGINX_USER:-${NGIX_USER:-}}"
  NGINX_PASSWORD="${NGINX_PASSWORD:-${NGIX_PASSWORD:-}}"

  [[ -n "${NGINX_USER:-}" ]] || fail "NGINX_USER (or NGIX_USER) is missing from ${SECRET_FILE}"
  [[ -n "${NGINX_PASSWORD:-}" ]] || fail "NGINX_PASSWORD (or NGIX_PASSWORD) is missing from ${SECRET_FILE}"
}

# nginx:1.27-alpine runs on musl, whose crypt(3) does NOT implement bcrypt ($2y$).
# Apache's apr1 ($apr1$) is the strongest format nginx can verify there, so
# generate that — a bcrypt hash would make every login fail with a 401.
generate_htpasswd() {
  require_command htpasswd
  htpasswd -nb "$NGINX_USER" "$NGINX_PASSWORD"
}

non_secret_value() {
  local key="$1"

  if [[ -n "${!key:-}" ]]; then
    printf '%s' "${!key}"
    return 0
  fi

  # Fall back to the local .env.example defaults so the script works without a
  # populated .env for values that are genuinely not secret.
  sed -nE "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*(.*)$/\1/p" \
    "${COMPOSE_DIR}/.env.example" 2>/dev/null | head -n 1
}

# ── Build the deployment bundle ───────────────────────────────────────────────
build_bundle() {
  local bundle_dir="${WORK_DIR}/bundle"

  mkdir -p "${bundle_dir}/nginx"

  local db_name api_port registry registry_namespace mongo_root_user
  db_name="$(non_secret_value DB_NAME)"
  api_port="$(non_secret_value API_PORT)"
  registry="$(non_secret_value REGISTRY)"
  registry_namespace="$(non_secret_value REGISTRY_NAMESPACE)"
  mongo_root_user="$(non_secret_value MONGO_ROOT_USER)"

  [[ -n "${API_TAG:-}" ]] || fail "API_TAG is not set. Export the short commit SHA before deploying."
  [[ -n "${FRONT_TAG:-}" ]] || fail "FRONT_TAG is not set. Export the short commit SHA before deploying."
  [[ "$API_TAG" != "latest" ]] || fail "API_TAG must not be 'latest'."
  [[ "$FRONT_TAG" != "latest" ]] || fail "FRONT_TAG must not be 'latest'."

  local mongo_uri="mongodb://readtracker:${MONGO_PASSWORD}@mongodb:27017/${db_name}?authSource=admin"

  # Rendered environment file for Compose on the VM.
  cat > "${bundle_dir}/.env" <<EOF
REGISTRY=${registry}
REGISTRY_NAMESPACE=${registry_namespace}
API_TAG=${API_TAG}
FRONT_TAG=${FRONT_TAG}
DB_NAME=${db_name}
API_PORT=${api_port}
MONGO_ROOT_USER=${mongo_root_user}
MONGO_ROOT_PASSWORD=${MONGO_ROOT_PASSWORD}
MONGO_PASSWORD=${MONGO_PASSWORD}
MONGO_URI=${mongo_uri}
EOF
  chmod 600 "${bundle_dir}/.env"

  # Basic Auth file for nginx, derived from the username and password so the
  # secret file never has to carry a pre-hashed value.
  generate_htpasswd > "${bundle_dir}/nginx/.htpasswd"
  chmod 600 "${bundle_dir}/nginx/.htpasswd"

  # Compose file and static configuration.
  cp "${COMPOSE_DIR}/docker-compose.prod.yml" "${bundle_dir}/docker-compose.prod.yml"
  cp "${COMPOSE_DIR}/nginx/default.conf" "${bundle_dir}/nginx/default.conf"
  cp "${COMPOSE_DIR}/nginx/rate_limit.conf" "${bundle_dir}/nginx/rate_limit.conf"

  # MongoDB first-boot user, rendered from the template with the real password and
  # the configured database name. The database must match DB_NAME so the user is
  # authorized on the database the API writes to.
  sed -e "s|__MONGO_PASSWORD__|${MONGO_PASSWORD}|g" \
      -e "s|__MONGO_DB__|${db_name}|g" \
    "${COMPOSE_DIR}/mongo-init.js.tpl" > "${bundle_dir}/mongo-init.js"
  chmod 600 "${bundle_dir}/mongo-init.js"
}

# ── Ship and start ────────────────────────────────────────────────────────────
transfer_bundle() {
  local bundle_dir="${WORK_DIR}/bundle"

  # REMOTE_ROOT itself is created by cloud-init and owned by root, so it must not
  # be chmod'd here — only the compose directory this script owns.
  log "Preparing ${REMOTE_COMPOSE_DIR} on the VM..."
  ssh_run "mkdir -p $(printf '%q' "$REMOTE_COMPOSE_DIR/nginx") && chmod 700 $(printf '%q' "$REMOTE_COMPOSE_DIR")"

  log "Copying configuration to the VM..."
  scp_run "${bundle_dir}/.env" "${bundle_dir}/docker-compose.prod.yml" \
    "$(ssh_target):${REMOTE_COMPOSE_DIR}/"
  # .htpasswd and mongo-init.js are deliberately NOT copied here — they are
  # installed below with container-appropriate ownership via a staging path.
  scp_run "${bundle_dir}/nginx/default.conf" "${bundle_dir}/nginx/rate_limit.conf" \
    "$(ssh_target):${REMOTE_COMPOSE_DIR}/nginx/"

  log "Restricting permissions on the VM..."
  ssh_run "chmod 600 $(printf '%q' "${REMOTE_COMPOSE_DIR}/.env")"

  # Files a container must read cannot be owned by the deploy user: the container
  # process runs as its own uid and would get EACCES. Both of these also hold
  # secrets, so they must not be world-readable either. Uploading to a staging
  # path and installing with sudo avoids the ownership deadlock a plain scp-over
  # creates — once a file is owned by the container's uid, the deploy user can no
  # longer overwrite it.
  #
  #   mongo-init.js → uid 999 (mongodb), read by the entrypoint on first boot
  #   .htpasswd     → uid 101 (nginx), read by the nginx workers, not just master
  log "Installing container-readable files with the correct ownership..."

  scp_run "${bundle_dir}/mongo-init.js" "$(ssh_target):${REMOTE_COMPOSE_DIR}/mongo-init.js.staged"
  scp_run "${bundle_dir}/nginx/.htpasswd" "$(ssh_target):${REMOTE_COMPOSE_DIR}/nginx/.htpasswd.staged"

  local init_script htpasswd_file
  init_script="$(printf '%q' "${REMOTE_COMPOSE_DIR}/mongo-init.js")"
  htpasswd_file="$(printf '%q' "${REMOTE_COMPOSE_DIR}/nginx/.htpasswd")"

  ssh_run "sudo install -o 999 -g 999 -m 600 $(printf '%q' "${REMOTE_COMPOSE_DIR}/mongo-init.js.staged") ${init_script} && rm -f $(printf '%q' "${REMOTE_COMPOSE_DIR}/mongo-init.js.staged")" \
    || fail "Could not install mongo-init.js for the mongodb user. The container will fail to read it (EACCES)."

  ssh_run "sudo install -o 101 -g 101 -m 640 $(printf '%q' "${REMOTE_COMPOSE_DIR}/nginx/.htpasswd.staged") ${htpasswd_file} && rm -f $(printf '%q' "${REMOTE_COMPOSE_DIR}/nginx/.htpasswd.staged")" \
    || fail "Could not install .htpasswd for the nginx user. nginx will return 500 on every authenticated request."
}

registry_login() {
  [[ -n "${REGISTRY_USER:-}" && -n "${REGISTRY_PASSWORD:-}" ]] || {
    log "Registry credentials absent from the secret file; skipping docker login."
    return 0
  }

  local registry
  registry="$(non_secret_value REGISTRY)"

  log "Logging in to ${registry} on the VM..."
  printf '%s' "$REGISTRY_PASSWORD" | ssh_run \
    "docker login $(printf '%q' "$registry") -u $(printf '%q' "$REGISTRY_USER") --password-stdin" >/dev/null
}

start_workload() {
  log "Pulling images and starting the workload..."
  # --force-recreate is required, not merely convenient. Docker resolves a
  # single-file bind mount to an inode when the container is *created*; replacing
  # the file on the host (which `install` does, to change ownership) leaves the
  # container pointing at the stale inode. Without a recreate, the container
  # keeps reading the previous .htpasswd / mongo-init.js and nginx returns 500.
  if ! ssh_run "cd $(printf '%q' "$REMOTE_COMPOSE_DIR") && docker compose -f docker-compose.prod.yml pull --quiet && docker compose -f docker-compose.prod.yml up -d --force-recreate"; then
    report_failing_services
    fail "docker compose up failed"
  fi
}

report_failing_services() {
  local failed

  failed="$(ssh_run "cd $(printf '%q' "$REMOTE_COMPOSE_DIR") && docker compose -f docker-compose.prod.yml ps --format '{{.Service}} {{.State}}'" 2>/dev/null \
    | awk '$2 != "running" { print $1 }')" || true

  if [[ -n "$failed" ]]; then
    printf '[app-vm] Services not running: %s\n' "$(printf '%s' "$failed" | tr '\n' ' ')" >&2
  else
    printf '[app-vm] Could not determine which service failed; inspect: ssh %s "cd %s && docker compose logs"\n' \
      "$(ssh_target)" "$REMOTE_COMPOSE_DIR" >&2
  fi
}

# ── Verification ──────────────────────────────────────────────────────────────
verify_entrypoint() {
  local host status attempt

  host="$(resolve_ssh_host)"
  log "Verifying the entrypoint at http://${host}/ ..."

  for attempt in $(seq 1 "$HEALTH_RETRIES"); do
    status="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://${host}/" 2>/dev/null)" || status="000"

    if [[ "$status" == "401" ]]; then
      log "Entrypoint is up and enforcing authentication (HTTP 401 without credentials)."
      return 0
    fi

    sleep "$HEALTH_SECONDS"
  done

  fail "Entrypoint did not return 401 (last status: ${status}). The nginx config or the auth file may not be mounted; inspect: ssh $(ssh_target) \"cd ${REMOTE_COMPOSE_DIR} && docker compose logs front\""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  require_command "$TERRAFORM_BIN"
  require_command "$SSH_BIN"
  require_command "$SCP_BIN"
  require_command "$SOPS_BIN"
  require_command htpasswd
  require_command curl

  make_work_dir

  log "Loading secrets from ${SECRET_FILE}..."
  load_secrets

  log "Building the deployment bundle..."
  build_bundle

  wait_for_ssh
  wait_for_docker
  transfer_bundle
  registry_login
  start_workload
  verify_entrypoint

  log "Deployment complete. The workload is running at http://$(resolve_ssh_host)/"
}

main "$@"
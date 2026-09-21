#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./mongodb-vm-common.sh
source "${SCRIPT_DIR}/mongodb-vm-common.sh"

require_command "$TERRAFORM_BIN"
require_command "$SSH_BIN"
ensure_dump_dir

if ! vm_is_provisioned; then
  log "Terraform output 'private_ip' is unavailable; skipping MongoDB backup because no VM is currently provisioned."
  exit 0
fi

log "Preparing MongoDB backup from $(resolve_ssh_host)..."
wait_for_ssh
wait_for_mongodb

tmp_dump_file="${DUMP_FILE}.tmp"
rm -f "$tmp_dump_file"

dump_command="mongodump --uri $(shell_quote "$(mongo_uri)") --db $(shell_quote "$MONGO_DB_NAME") --archive --gzip"

log "Saving MongoDB dump to ${DUMP_FILE}..."
if ssh_run "$dump_command" > "$tmp_dump_file"; then
  if [[ ! -s "$tmp_dump_file" ]]; then
    rm -f "$tmp_dump_file"
    fail "MongoDB dump completed without producing a local archive"
  fi

  mv "$tmp_dump_file" "$DUMP_FILE"
  log "MongoDB backup saved successfully."
  exit 0
fi

rm -f "$tmp_dump_file"
fail "MongoDB dump failed; Terraform destroy was not started"

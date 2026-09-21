#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./mongodb-vm-common.sh
source "${SCRIPT_DIR}/mongodb-vm-common.sh"

ensure_dump_dir

if [[ ! -f "$DUMP_FILE" ]]; then
  log "No local MongoDB dump found at ${DUMP_FILE}; skipping restore."
  exit 0
fi

require_command "$SSH_BIN"

log "Preparing MongoDB restore to $(resolve_ssh_host) from ${DUMP_FILE}..."
wait_for_ssh
wait_for_mongodb

restore_command="mongorestore --uri $(shell_quote "$(mongo_uri)") --nsInclude $(shell_quote "${MONGO_DB_NAME}.*") --drop --archive --gzip"

log "Restoring MongoDB dump into the provisioned VM..."
ssh_run "$restore_command" < "$DUMP_FILE"
log "MongoDB restore completed successfully."

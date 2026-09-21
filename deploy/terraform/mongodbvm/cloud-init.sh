#!/bin/bash
set -euo pipefail

LOG="/var/log/cloud-init-mongo.log"
MONGO_DATA_DIR="/var/lib/mongodb"
exec > >(tee -a "$LOG") 2>&1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

find_data_device() {
  local root_source root_disk

  root_source="$(findmnt -n -o SOURCE /)"
  root_disk="/dev/$(lsblk -no PKNAME "$root_source")"

  lsblk -dpno NAME,TYPE \
    | awk '$2 == "disk" { print $1 }' \
    | grep -vx "$root_disk" \
    | head -n 1
}

wait_for_data_device() {
  local attempt data_device

  for attempt in $(seq 1 60); do
    if data_device="$(find_data_device)"; then
      :
    else
      data_device=""
    fi

    if [ -n "$data_device" ]; then
      echo "$data_device"
      return 0
    fi

    sleep 2
  done

  return 1
}

log "=== Starting MongoDB cloud-init setup ==="

# Install MongoDB CE 8.0 on Ubuntu 24.04
log "Importing MongoDB GPG key..."
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc \
  | gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg

log "Adding MongoDB apt repository..."
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] \
  https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" \
  > /etc/apt/sources.list.d/mongodb-org-8.0.list

log "Running apt-get update..."
apt-get update -y

log "Installing mongodb-org and conntrack..."
apt-get install -y conntrack mongodb-org

if systemctl is-active --quiet mongod; then
  log "Stopping mongod before preparing the persistent data volume..."
  systemctl stop mongod
fi

log "Waiting for the persistent MongoDB data volume..."
DATA_DEVICE="$(wait_for_data_device)"
log "Using data device: $DATA_DEVICE"

if ! blkid "$DATA_DEVICE" > /dev/null 2>&1; then
  log "Formatting $DATA_DEVICE with ext4..."
  mkfs.ext4 -F "$DATA_DEVICE"
else
  log "Existing filesystem detected on $DATA_DEVICE; skipping format."
fi

mkdir -p "$MONGO_DATA_DIR"
DATA_UUID="$(blkid -s UUID -o value "$DATA_DEVICE")"

if ! grep -q "UUID=$DATA_UUID $MONGO_DATA_DIR " /etc/fstab; then
  log "Persisting mount in /etc/fstab..."
  echo "UUID=$DATA_UUID $MONGO_DATA_DIR ext4 defaults,nofail 0 2" >> /etc/fstab
fi

if ! mountpoint -q "$MONGO_DATA_DIR"; then
  log "Mounting $DATA_DEVICE on $MONGO_DATA_DIR..."
  mount "$MONGO_DATA_DIR"
fi

chown mongodb:mongodb "$MONGO_DATA_DIR"

log "Reloading systemd and starting mongod..."
systemctl daemon-reload
systemctl enable mongod
systemctl start mongod

# Wait for mongod to be ready
log "Waiting for mongod to be ready..."
until mongosh --quiet --eval "db.runCommand({ ping: 1 })" > /dev/null 2>&1; do
  sleep 1
done
log "mongod is ready."

if mongosh admin --quiet --eval "db.getUser('readtracker') ? 'present' : 'missing'" | grep -q "present"; then
  log "readtracker user already exists; skipping creation."
else
  log "Creating readtracker user..."
  mongosh admin --eval "
    db.createUser({
      user: 'readtracker',
      pwd: '${mongo_password}',
      roles: [{ role: 'readWrite', db: 'read_tracker' }]
    })
  "
  log "User created successfully."
fi

# Bind to all interfaces so pods can reach the VM over the private network
log "Configuring mongod.conf (bindIp + auth)..."
python3 <<'PY'
from pathlib import Path

path = Path("/etc/mongod.conf")
lines = path.read_text().splitlines()

new_lines = []
bind_updated = False
security_index = None
next_root_index = None
authorization_updated = False

for index, line in enumerate(lines):
    stripped = line.strip()
    if stripped.startswith("bindIp:"):
        indent = line[: len(line) - len(line.lstrip())]
        new_lines.append(f"{indent}bindIp: 0.0.0.0")
        bind_updated = True
    else:
        new_lines.append(line)

    if stripped == "security:" and security_index is None:
        security_index = index
        continue

    if security_index is not None and index > security_index and line and not line.startswith(" "):
        next_root_index = index
        break

if security_index is None:
    if new_lines and new_lines[-1] != "":
        new_lines.append("")
    new_lines.extend(["security:", "  authorization: enabled"])
else:
    section_end = next_root_index if next_root_index is not None else len(new_lines)
    for index in range(security_index + 1, section_end):
        stripped = new_lines[index].strip()
        if stripped.startswith("authorization:"):
            new_lines[index] = "  authorization: enabled"
            authorization_updated = True
            break
    if not authorization_updated:
        insert_at = next_root_index if next_root_index is not None else len(new_lines)
        new_lines.insert(insert_at, "  authorization: enabled")

if not bind_updated:
    raise SystemExit("bindIp setting not found in /etc/mongod.conf")

path.write_text("\n".join(new_lines) + "\n")
PY

log "Restarting mongod with auth enabled..."
systemctl restart mongod
log "=== MongoDB cloud-init setup complete ==="

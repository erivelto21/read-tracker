#!/bin/bash
set -euo pipefail

LOG="/var/log/cloud-init-app.log"
DATA_MOUNT="/srv/read-tracker"
# The user scripts/app-vm-deploy.sh connects as. It needs docker group access
# and write permission on the data mount.
DEPLOY_USER="ubuntu"
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

# NOTE: this script intentionally receives no secrets. Application credentials,
# the Basic Auth file, and the registry login are delivered by
# scripts/app-vm-deploy.sh after provisioning, so they never reach Terraform state.

log "=== Starting application VM cloud-init setup ==="

# ── Base packages ─────────────────────────────────────────────────────────────
log "Running apt-get update..."
apt-get update -y

log "Installing prerequisites..."
apt-get install -y ca-certificates curl gnupg lsb-release

# ── Docker Engine + Compose plugin ────────────────────────────────────────────
log "Installing Docker Engine from the official repository..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

log "Enabling and starting Docker..."
systemctl enable docker
systemctl start docker

log "Verifying Docker and the Compose plugin..."
docker --version
docker compose version

# The deploy step runs `docker` over SSH as an unprivileged user, so that user
# must be in the docker group. Without this, `docker info` fails without sudo and
# the deploy aborts while waiting for Docker to become ready.
log "Granting the deploy user access to the Docker daemon..."
usermod -aG docker "${DEPLOY_USER}"
log "Added ${DEPLOY_USER} to the docker group (takes effect on the next SSH session)."

# ── Persistent data volume ────────────────────────────────────────────────────
log "Waiting for the persistent data volume..."
DATA_DEVICE="$(wait_for_data_device)"
log "Using data device: $DATA_DEVICE"

if ! blkid "$DATA_DEVICE" > /dev/null 2>&1; then
  log "Formatting $DATA_DEVICE with ext4..."
  mkfs.ext4 -F "$DATA_DEVICE"
else
  log "Existing filesystem detected on $DATA_DEVICE; skipping format."
fi

mkdir -p "$DATA_MOUNT"
DATA_UUID="$(blkid -s UUID -o value "$DATA_DEVICE")"

if ! grep -q "UUID=$DATA_UUID $DATA_MOUNT " /etc/fstab; then
  log "Persisting mount in /etc/fstab..."
  echo "UUID=$DATA_UUID $DATA_MOUNT ext4 defaults,nofail 0 2" >> /etc/fstab
fi

if ! mountpoint -q "$DATA_MOUNT"; then
  log "Mounting $DATA_DEVICE on $DATA_MOUNT..."
  mount "$DATA_MOUNT"
fi

# The deploy step writes the Compose file, environment file, and nginx config
# into this directory, so it must exist and be writable by the deploying user.
# MongoDB writes to its data directory as the container's mongodb user (uid 999
# in the official image), so that one is chowned separately.
mkdir -p "$DATA_MOUNT/mongodb" "$DATA_MOUNT/compose"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "$DATA_MOUNT/compose"
chown -R 999:999 "$DATA_MOUNT/mongodb"

# ── SSH hardening ─────────────────────────────────────────────────────────────
log "Hardening SSH..."
cat > /etc/ssh/sshd_config.d/99-read-tracker.conf <<'EOF'
PasswordAuthentication no
PermitRootLogin prohibit-password
EOF

# Ubuntu ships ssh.service, not sshd.service. Reloading picks up the drop-in
# above without dropping the session cloud-init is running over. Neither failure
# is fatal — the drop-in is already on disk — so this must not abort the script.
systemctl reload ssh || systemctl restart ssh || log "WARNING: could not reload SSH; the drop-in is applied on the next restart."

log "=== Application VM cloud-init setup complete ==="
log "Data volume mounted at $DATA_MOUNT"
log "Docker is ready — run 'make app-vm-deploy' to deliver configuration and start the workload"
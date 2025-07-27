#!/bin/bash

# Fixed configuration
# https://slugs.do-api.dev/
REGION="nyc3"
SIZE="s-8vcpu-16gb"
IMAGE="debian-12-x64"
TAG="kage-cli,pentest"
WAIT="--wait"
#export DIGITALOCEAN_ACCESS_TOKEN="dop_v1_ed5[...]"

# https://docs.digitalocean.com/reference/doctl/
# Check if doctl is available
command -v doctl >/dev/null 2>&1 || { echo >&2 "doctl is not installed. Aborting."; exit 1; }

ACTION="$1"
RESOURCE="$2"
NAME="$3"
PASSWORD="$4"
SNAPSHOT_OLD=""
SNAPSHOT_NEW="${NAME}-snapshot-$(date +%s)"

if [[ -z "$ACTION" || -z "$RESOURCE" || -z "$NAME" ]]; then
  echo "Usage: $0 [create|start|stop|ssh] machine <name> [password]"
  exit 1
fi

get_droplet_id() {
  doctl compute droplet list --format ID,Name | grep "$NAME" | awk '{print $1}'
}

get_snapshot_id_by_name() {
  doctl compute image list-user --format ID,Name | grep "$1" | awk '{print $1}'
}

case "$ACTION" in
  create)
    # Generate a strong 12-character password (A-Za-z0-9 and common punctuation)
    GEN_PASSWORD=$(openssl rand -base64 12 | tr -dc '[:alnum:][:punct:]' | head -c 12)
    echo "[+] Root password generated: $GEN_PASSWORD"
    echo "$NAME -> $GEN_PASSWORD" >> current_pass.txt
    echo "[+] Creating droplet $NAME with custom password..."
    CLOUD_INIT_FILE="/tmp/cloud-init-${NAME}.yml"
    cat > "$CLOUD_INIT_FILE" <<EOF
#cloud-config
chpasswd:
  list: |
    root:$GEN_PASSWORD
  expire: False
ssh_pwauth: true
EOF

    doctl compute droplet create "$NAME" \
      --region "$REGION" \
      --image "$IMAGE" \
      --size "$SIZE" \
      --tag-names "$TAG" \
      --user-data-file "$CLOUD_INIT_FILE" \
      $WAIT

    echo "[+] Waiting for droplet to appear..."
    sleep 10

    ID=$(get_droplet_id)
    echo "[+] Creating snapshot $SNAPSHOT_NEW..."
    doctl compute droplet-action snapshot "$ID" --snapshot-name "$SNAPSHOT_NEW"

    echo "[+] Waiting 60s to ensure snapshot has started..."
    sleep 60

    echo "[+] Deleting droplet $NAME..."
    doctl compute droplet delete "$ID" --force

    rm -f "$CLOUD_INIT_FILE"
    ;;
  
  start)
    echo "[+] Restoring droplet $NAME from latest snapshot..."
    SNAP_IMAGE=$(doctl compute image list-user --format ID,Name | grep "${NAME}-snapshot" | sort | tail -n 1 | awk '{print $1}')

    if [[ -z "$SNAP_IMAGE" ]]; then
      echo "[ERROR] No snapshot found for $NAME."
      exit 1
    fi

    # Generate a strong 12-character password
    GEN_PASSWORD=$(openssl rand -base64 12 | tr -dc '[:alnum:][:punct:]' | head -c 12)
    echo "[+] Root password generated: $GEN_PASSWORD"
    echo "$NAME -> $GEN_PASSWORD" >> current_pass.txt
    CLOUD_INIT_FILE="/tmp/cloud-init-${NAME}.yml"
    cat > "$CLOUD_INIT_FILE" <<EOF
#cloud-config
chpasswd:
  list: |
    root:$GEN_PASSWORD
  expire: False
ssh_pwauth: true
EOF
    doctl compute droplet create "$NAME" \
      --region "$REGION" \
      --image "$SNAP_IMAGE" \
      --size "$SIZE" \
      --tag-names "$TAG" \
      --user-data-file "$CLOUD_INIT_FILE" \
      $WAIT
    rm -f "$CLOUD_INIT_FILE"
    ;;

  stop)
    ID=$(get_droplet_id)
    if [[ -z "$ID" ]]; then
      echo "[ERROR] Droplet $NAME not found."
      exit 1
    fi

    echo "[+] Creating new snapshot $SNAPSHOT_NEW..."
    doctl compute droplet-action snapshot "$ID" --snapshot-name "$SNAPSHOT_NEW"
    echo "[+] Waiting 60s to ensure snapshot has started..."
    sleep 60

    echo "[+] Deleting droplet $NAME..."
    doctl compute droplet delete "$ID" --force

    echo "[+] Checking number of snapshots for $NAME..."
    SNAPSHOTS_LIST=$(doctl compute image list-user --format Name | grep "${NAME}-snapshot" | sort)
    SNAPSHOTS_COUNT=$(echo "$SNAPSHOTS_LIST" | wc -l | tr -d ' ')
    SNAPSHOT_OLD=$(echo "$SNAPSHOTS_LIST" | head -n 1)

    if [[ "$SNAPSHOTS_COUNT" -gt 1 && "$SNAPSHOT_OLD" != "$SNAPSHOT_NEW" ]]; then
      OLD_ID=$(get_snapshot_id_by_name "$SNAPSHOT_OLD")
      echo "[+] Deleting old snapshot: $SNAPSHOT_OLD... (total snapshots: $SNAPSHOTS_COUNT)"
      doctl compute image delete "$OLD_ID" --force
    else
      echo "[!] No multiple snapshots found, no old snapshot will be deleted. (total snapshots: $SNAPSHOTS_COUNT)"
    fi
    ;;
  
  ssh)
    ID=$(get_droplet_id)
    if [[ -z "$ID" ]]; then
      echo "[ERROR] Droplet $NAME not found."
      exit 1
    fi
    echo "[+] Connecting via SSH to droplet $NAME (ID: $ID)..."
    doctl compute ssh "$ID"
    ;;
  *)
    echo "[ERROR] Invalid action: $ACTION. Use create, start, stop or ssh."
    exit 1
    ;;
esac

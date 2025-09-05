#!/bin/bash
set -e

# ===== Variables (edit as needed) =====
MYSQL_DB="nextcloud"
MYSQL_USER="ncuser"
MYSQL_PASS="YourDbUserPass123!"
MYSQL_ROOT_PASS="YourRootPass123!"
ADMIN_USER="Abhinav"
ADMIN_PASS="Abhinav@2004"
SHARED_FOLDER="$HOME/SharedFolder"
NGROK_BIN="$HOME/ngrok"  # path to ngrok binary

# ===== Setup Shared Folder =====
mkdir -p "$SHARED_FOLDER"

# ===== Create Persistent Volume & Network =====
docker volume create nextcloud_db
docker network inspect nextcloud-net >/dev/null 2>&1 || docker network create nextcloud-net

# ===== Run MariaDB =====
docker rm -f mariadb >/dev/null 2>&1 || true
docker run -d \
  --name mariadb \
  --network nextcloud-net \
  -e MARIADB_DATABASE=$MYSQL_DB \
  -e MARIADB_USER=$MYSQL_USER \
  -e MARIADB_PASSWORD=$MYSQL_PASS \
  -e MARIADB_ROOT_PASSWORD=$MYSQL_ROOT_PASS \
  -v nextcloud_db:/var/lib/mysql \
  mariadb:11.4 \
  --transaction-isolation=READ-COMMITTED \
  --binlog-format=ROW

# ===== Run Nextcloud =====
docker rm -f nextcloud >/dev/null 2>&1 || true
docker run -d \
  --name nextcloud \
  --network nextcloud-net \
  -p 8080:80 \
  -e MYSQL_DATABASE=$MYSQL_DB \
  -e MYSQL_USER=$MYSQL_USER \
  -e MYSQL_PASSWORD=$MYSQL_PASS \
  -e MYSQL_HOST=mariadb \
  -e NEXTCLOUD_ADMIN_USER=$ADMIN_USER \
  -e NEXTCLOUD_ADMIN_PASSWORD=$ADMIN_PASS \
  -v "$SHARED_FOLDER:/var/www/html/data" \
  nextcloud

# ===== Start Ngrok in background =====
$NGROK_BIN http 8080 > /dev/null &
sleep 5

# ===== Fetch Ngrok Public URL =====
NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o '"https://[^"]*' | head -n 1 | sed 's/"//')

if [ -z "$NGROK_URL" ]; then
  echo "❌ Failed to fetch Ngrok URL"
  exit 1
fi

# ===== Add Ngrok URL to Nextcloud Trusted Domains =====
docker exec -u www-data nextcloud php occ config:system:set trusted_domains 2 --value="$NGROK_URL"

echo "✅ Setup complete!"
echo "➡ Local access: http://localhost:8080"
echo "➡ Public access: $NGROK_URL"


# To run, use - 
# chmod +x setup.sh
# ./setup.sh

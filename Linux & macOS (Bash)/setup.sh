#!/bin/bash
set -e

# Variables (edit before running)
MYSQL_DB="nextcloud"
MYSQL_USER="ncuser"
MYSQL_PASS="YourDbUserPass123!"
MYSQL_ROOT_PASS="YourRootPass123!"
ADMIN_USER="Abhinav"
ADMIN_PASS="Abhinav@2004"
SHARED_FOLDER="$HOME/SharedFolder"

# Create shared folder if missing
mkdir -p "$SHARED_FOLDER"

# Create persistent DB volume
docker volume create nextcloud_db

# Create network if not exists
docker network inspect nextcloud-net >/dev/null 2>&1 || docker network create nextcloud-net

# Run MariaDB
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

# Run Nextcloud
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

echo "✅ Setup complete!"
echo "➡ Access locally: http://localhost:8080"
echo "➡ Run 'ngrok http 8080' to expose Nextcloud"

# To run, use - 
# chmod +x setup.sh
# ./setup.sh

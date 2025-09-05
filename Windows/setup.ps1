# ===== Variables =====
$MYSQL_DB = "nextcloud"
$MYSQL_USER = "ncuser"
$MYSQL_PASS = "YourDbUserPass123!"
$MYSQL_ROOT_PASS = "YourRootPass123!"
$ADMIN_USER = "Abhinav"
$ADMIN_PASS = "Abhinav@2004"
$SHARED_FOLDER = "E:\SharedFolder"
$NGROK_BIN = "C:\ngrok\ngrok.exe"   # path to ngrok binary

# ===== Setup Shared Folder =====
if (!(Test-Path $SHARED_FOLDER)) { New-Item -ItemType Directory -Path $SHARED_FOLDER | Out-Null }

# ===== Create Volume & Network =====
docker volume create nextcloud_db | Out-Null
if (-not (docker network ls --format '{{.Name}}' | Select-String -Pattern 'nextcloud-net')) {
    docker network create nextcloud-net | Out-Null
}

# ===== Run MariaDB =====
docker rm -f mariadb | Out-Null
docker run -d `
  --name mariadb `
  --network nextcloud-net `
  -e MARIADB_DATABASE=$MYSQL_DB `
  -e MARIADB_USER=$MYSQL_USER `
  -e MARIADB_PASSWORD=$MYSQL_PASS `
  -e MARIADB_ROOT_PASSWORD=$MYSQL_ROOT_PASS `
  -v nextcloud_db:/var/lib/mysql `
  mariadb:11.4 `
  --transaction-isolation=READ-COMMITTED `
  --binlog-format=ROW | Out-Null

# ===== Run Nextcloud =====
docker rm -f nextcloud | Out-Null
docker run -d `
  --name nextcloud `
  --network nextcloud-net `
  -p 8080:80 `
  -e MYSQL_DATABASE=$MYSQL_DB `
  -e MYSQL_USER=$MYSQL_USER `
  -e MYSQL_PASSWORD=$MYSQL_PASS `
  -e MYSQL_HOST=mariadb `
  -e NEXTCLOUD_ADMIN_USER=$ADMIN_USER `
  -e NEXTCLOUD_ADMIN_PASSWORD=$ADMIN_PASS `
  -v "$SHARED_FOLDER:/var/www/html/data" `
  nextcloud | Out-Null

# ===== Start Ngrok in background =====
Start-Process -NoNewWindow -FilePath $NGROK_BIN -ArgumentList "http 8080"
Start-Sleep -Seconds 5

# ===== Fetch Ngrok URL =====
$Response = Invoke-RestMethod -Uri "http://127.0.0.1:4040/api/tunnels"
$NgrokUrl = $Response.tunnels[0].public_url

if (-not $NgrokUrl) {
    Write-Host "❌ Failed to fetch Ngrok URL"
    exit
}

# ===== Add to Trusted Domains =====
docker exec -u www-data nextcloud php occ config:system:set trusted_domains 2 --value="$NgrokUrl"

Write-Host "✅ Setup complete!"
Write-Host "➡ Local access: http://localhost:8080"
Write-Host "➡ Public access: $NgrokUrl"

# To run, use - 
# .\setup.ps1

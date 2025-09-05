# 🚀 Personal Cloud with Nextcloud, MariaDB & Ngrok

This project sets up a **self-hosted personal cloud** using [Nextcloud](https://nextcloud.com/) in Docker, with persistent storage, a MariaDB backend, and **public access via ngrok**.

It also allows you to expose a local folder (`E:\SharedFolder`) as a shared, internet-accessible folder.

---

## 📌 Prerequisites

### 🔹 Install Docker

* **Windows/macOS** → [Download Docker Desktop](https://www.docker.com/products/docker-desktop)
* **Linux (Debian/Ubuntu)**:

  ```bash
  sudo apt update
  sudo apt install docker.io -y
  sudo systemctl enable --now docker
  ```
* Verify installation:

  ```bash
  docker --version
  ```

### 🔹 Install Ngrok

1. Create a free account at [ngrok.com](https://ngrok.com/).
2. Download ngrok for your OS.
3. Authenticate with your token:

   ```bash
   ngrok config add-authtoken YOUR_TOKEN_HERE
   ```

### 🔹 Create a Shared Folder

On your system, create the folder you want to expose. Example:

* Windows: `E:\SharedFolder`
* Linux: `/home/username/SharedFolder`

---

## ⚙️ Step 1: Run n8n (Optional Automation Tool)

```bash
docker run -it --rm --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n n8nio/n8n
```

Runs **n8n** workflow automation on port `5678`.

---

## ⚙️ Step 2: Create Persistent Volume for Database

```bash
docker volume create nextcloud_db
```

Ensures MariaDB data persists across container restarts.

---

## ⚙️ Step 3: Run MariaDB

```bash
docker run -d \
  --name mariadb \
  --network nextcloud-net \
  -e MARIADB_DATABASE=nextcloud \
  -e MARIADB_USER=ncuser \
  -e MARIADB_PASSWORD="YourDbUserPass123!" \
  -e MARIADB_ROOT_PASSWORD="YourRootPass123!" \
  -v nextcloud_db:/var/lib/mysql \
  mariadb:11.4 \
  --transaction-isolation=READ-COMMITTED \
  --binlog-format=ROW
```

Creates a MariaDB container with persistent storage.

---

## ⚙️ Step 4: Run Nextcloud

```bash
docker run -d \
  --name nextcloud \
  --network nextcloud-net \
  -p 8080:80 \
  -e MYSQL_DATABASE=nextcloud \
  -e MYSQL_USER=ncuser \
  -e MYSQL_PASSWORD="YourDbUserPass123!" \
  -e MYSQL_HOST=mariadb \
  -e NEXTCLOUD_ADMIN_USER=Abhinav \
  -e NEXTCLOUD_ADMIN_PASSWORD="Abhinav@2004" \
  -v "E:\SharedFolder:/var/www/html/data" \
  nextcloud
```

Maps `E:\SharedFolder` to Nextcloud’s data directory.

* Access locally at: `http://localhost:8080`
* Admin user: `Abhinav` / `Abhinav@2004`

---

## ⚙️ Step 5: Connect Nextcloud & Database

```bash
docker network connect nextcloud-net nextcloud
```

---

## ⚙️ Step 6: Add Trusted Domain for Ngrok

```bash
docker exec -u www-data nextcloud php occ config:system:set trusted_domains 2 --value="https://YOUR_NGROK_URL/"
```

Replace with your actual ngrok URL.

---

## ⚙️ Step 7: Expose Nextcloud with Ngrok

```bash
ngrok http 8080
```

Ngrok gives you a public URL (e.g., `https://xxxx.ngrok-free.app`) to access your cloud.

---

## 📂 Folder Mapping

* **Local folder**: `E:\SharedFolder`
* **Nextcloud storage**: `/var/www/html/data`
* **Access**: `http://localhost:8080` or `https://YOUR_NGROK_URL/`

---

## 🔍 Verify

Check running containers:

```bash
docker ps
```

---

## 🛠️ Usage Notes

* **Persistence** → Files remain in `E:\SharedFolder`; DB persists in `nextcloud_db`
* **Public Access** → Managed via ngrok; restart ngrok if URL changes
* **Security** → Update all default credentials before real use

---

## 📌 Summary

This setup provides:

* ✅ A personal cloud with Nextcloud
* ✅ Persistent file storage & database
* ✅ Public access via ngrok
* ✅ Cross-platform setup (Windows/Linux)

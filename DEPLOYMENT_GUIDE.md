# Docker Deployment Guide - MFP Academy

## 🐳 Ringkasan Perubahan / Summary of Changes

Implementasi ini menambahkan dukungan Docker lengkap untuk aplikasi MFP Academy dengan fitur-fitur berikut:

### ✅ Yang Telah Ditambahkan:

1. **Dockerfile** - Multi-stage build untuk optimasi ukuran image
2. **Docker Compose** - Orchestration untuk menjalankan aplikasi dengan MySQL
3. **GitHub Actions** - Auto-build dan push ke GitHub Container Registry (ghcr.io)
4. **Migrasi Database** - Dari SQLite ke MySQL
5. **Dokumentasi Lengkap** - Panduan deployment di DOCKER.md

---

## 🚀 Cara Menjalankan dengan Docker Compose

### Langkah 1: Copy File Docker Compose

```bash
cp docker-compose.example.yml docker-compose.yml
```

### Langkah 2: Generate Application Key

```bash
docker run --rm ghcr.io/oclab/mfp-academy:latest php artisan key:generate --show
```

Output akan seperti: `base64:abcdefghijklmnopqrstuvwxyz1234567890...`

### Langkah 3: Edit docker-compose.yml

Buka file `docker-compose.yml` dan update baris berikut dengan key yang di-generate:

```yaml
- APP_KEY=base64:YOUR_APP_KEY_HERE  # Ganti dengan key dari langkah 2
```

### Langkah 4: Jalankan Container

```bash
# Start semua services
docker-compose up -d

# Cek status
docker-compose ps
```

### Langkah 5: Jalankan Migrasi Database

```bash
# Jalankan migrasi
docker-compose exec app php artisan migrate --force

# (Opsional) Seed database dengan data awal
docker-compose exec app php artisan db:seed
```

### Langkah 6: Akses Aplikasi

- **Aplikasi Utama**: http://localhost:8000
- **PHPMyAdmin**: http://localhost:8080
- **MailHog UI**: http://localhost:8025 (untuk testing email)

---

## 📋 Contoh docker-compose.yml Lengkap

```yaml
version: '3.8'

services:
  # Laravel Application
  app:
    image: ghcr.io/oclab/mfp-academy:latest
    container_name: mfp-academy-app
    restart: unless-stopped
    ports:
      - "8000:80"
    environment:
      # Application Settings
      - APP_NAME="MFP Academy"
      - APP_ENV=production
      - APP_KEY=base64:YOUR_APP_KEY_HERE  # Generate dengan: php artisan key:generate --show
      - APP_DEBUG=false
      - APP_URL=http://localhost:8000
      
      # Database Configuration
      - DB_CONNECTION=mysql
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_DATABASE=mfp_academy
      - DB_USERNAME=mfp_user
      - DB_PASSWORD=mfp_password
      
      # Cache and Session
      - CACHE_STORE=database
      - SESSION_DRIVER=database
      - QUEUE_CONNECTION=database
    depends_on:
      mysql:
        condition: service_healthy
    networks:
      - mfp-network
    volumes:
      - ./storage:/var/www/html/storage

  # MySQL Database
  mysql:
    image: mysql:8.0
    container_name: mfp-academy-mysql
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: mfp_academy
      MYSQL_USER: mfp_user
      MYSQL_PASSWORD: mfp_password
      MYSQL_ROOT_PASSWORD: root_password
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - mfp-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10

  # Optional: PHPMyAdmin
  phpmyadmin:
    image: phpmyadmin:latest
    container_name: mfp-academy-phpmyadmin
    restart: unless-stopped
    environment:
      PMA_HOST: mysql
      PMA_PORT: 3306
      PMA_USER: mfp_user
      PMA_PASSWORD: mfp_password
    ports:
      - "8080:80"
    depends_on:
      - mysql
    networks:
      - mfp-network

networks:
  mfp-network:
    driver: bridge

volumes:
  mysql-data:
    driver: local
```

---

## 🔧 Perintah-Perintah Berguna / Useful Commands

### Mengelola Container

```bash
# Melihat log aplikasi
docker-compose logs -f app

# Melihat log MySQL
docker-compose logs -f mysql

# Stop semua services
docker-compose down

# Stop dan hapus semua data (HATI-HATI!)
docker-compose down -v

# Restart service tertentu
docker-compose restart app
```

### Menjalankan Artisan Commands

```bash
# Clear cache
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear
docker-compose exec app php artisan view:clear

# Menjalankan queue worker
docker-compose exec app php artisan queue:work

# Masuk ke Tinker
docker-compose exec app php artisan tinker
```

### Database Management

```bash
# Backup database
docker-compose exec mysql mysqldump -u mfp_user -pmfp_password mfp_academy > backup.sql

# Restore database
docker-compose exec -T mysql mysql -u mfp_user -pmfp_password mfp_academy < backup.sql

# Akses MySQL console
docker-compose exec mysql mysql -u mfp_user -pmfp_password mfp_academy
```

---

## 🏗️ GitHub Actions - Auto Build & Push

Setiap kali ada push ke branch `main` atau `master`, GitHub Actions akan otomatis:

1. ✅ Build Docker image
2. ✅ Push ke GitHub Container Registry (ghcr.io)
3. ✅ Tag dengan berbagai format:
   - `latest` - untuk branch utama
   - `<branch-name>` - untuk branch tertentu
   - `v*` - untuk tagged releases

### Menggunakan Image dari GHCR

```bash
# Pull image terbaru
docker pull ghcr.io/oclab/mfp-academy:latest

# Atau gunakan tag spesifik
docker pull ghcr.io/oclab/mfp-academy:v1.0.0
```

---

## 🔐 Konfigurasi untuk Production

Untuk deployment production, pastikan:

1. ✅ Gunakan password yang kuat untuk database
2. ✅ Set `APP_DEBUG=false`
3. ✅ Set `APP_ENV=production`
4. ✅ Gunakan SSL/TLS dengan reverse proxy (nginx/Caddy/Traefik)
5. ✅ Setup backup database secara berkala
6. ✅ Monitor logs dan kesehatan aplikasi
7. ✅ Simpan environment variables dengan aman (gunakan Docker secrets)

### Contoh dengan Traefik (Reverse Proxy + SSL):

```yaml
services:
  app:
    image: ghcr.io/oclab/mfp-academy:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.mfp-academy.rule=Host(`yourdomain.com`)"
      - "traefik.http.routers.mfp-academy.entrypoints=websecure"
      - "traefik.http.routers.mfp-academy.tls.certresolver=letsencrypt"
```

---

## 📚 Dokumentasi Tambahan

Untuk informasi lebih lengkap, lihat file **DOCKER.md** di repository.

---

## ❓ Troubleshooting

### Container tidak mau start?

```bash
docker-compose logs app
docker-compose logs mysql
```

### Permission issues?

```bash
docker-compose exec app chown -R www-data:www-data /var/www/html/storage
docker-compose exec app chmod -R 755 /var/www/html/storage
```

### Database connection error?

Pastikan MySQL sudah ready (tunggu beberapa detik setelah `docker-compose up -d`):

```bash
docker-compose ps
# Status mysql harus 'healthy'
```

---

## 🎉 Summary

Dengan implementasi ini, aplikasi MFP Academy sekarang:

✅ Dapat dijalankan dengan satu command: `docker-compose up -d`  
✅ Menggunakan MySQL (bukan SQLite lagi)  
✅ Auto-build dan push ke ghcr.io via GitHub Actions  
✅ Siap untuk production deployment  
✅ Dokumentasi lengkap tersedia  

**Happy Deploying! 🚀**

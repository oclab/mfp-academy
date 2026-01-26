# Docker Setup Guide for MFP Academy

This guide explains how to run the MFP Academy application using Docker and Docker Compose.

## Prerequisites

- Docker Engine 20.10 or higher
- Docker Compose 2.0 or higher

## Quick Start with Docker Compose

### 1. Using Pre-built Image from GitHub Container Registry

The easiest way to run the application is using the pre-built Docker image from GitHub Container Registry (ghcr.io):

```bash
# Copy the example docker-compose file
cp docker-compose.example.yml docker-compose.yml

# Generate an application key
docker run --rm ghcr.io/oclab/mfp-academy:latest php artisan key:generate --show

# Update the APP_KEY in docker-compose.yml with the generated key

# Start the services
docker-compose up -d

# Run database migrations
docker-compose exec app php artisan migrate --force

# (Optional) Seed the database
docker-compose exec app php artisan db:seed
```

The application will be available at:
- **Application**: http://localhost:8000
- **PHPMyAdmin**: http://localhost:8080 (optional, if enabled)
- **MailHog UI**: http://localhost:8025 (optional, if enabled)

### 2. Building Locally

If you want to build the Docker image locally:

```bash
# Build the image
docker-compose build

# Start the services
docker-compose up -d

# Run database migrations
docker-compose exec app php artisan migrate --force
```

## Configuration

### Environment Variables

Key environment variables in `docker-compose.yml`:

- `APP_KEY`: Laravel application key (required)
- `APP_ENV`: Application environment (production/local)
- `APP_DEBUG`: Debug mode (true/false)
- `DB_HOST`: Database host (use service name: mysql)
- `DB_DATABASE`: Database name
- `DB_USERNAME`: Database username
- `DB_PASSWORD`: Database password

### Database Configuration

The application is configured to use MySQL by default. The database credentials are:
- **Database**: mfp_academy
- **User**: mfp_user
- **Password**: mfp_password
- **Root Password**: root_password

You can modify these in the `docker-compose.yml` file.

## Running Commands

Execute Laravel artisan commands inside the container:

```bash
# Run migrations
docker-compose exec app php artisan migrate

# Clear cache
docker-compose exec app php artisan cache:clear

# Create a user
docker-compose exec app php artisan tinker

# View logs
docker-compose logs -f app

# Access MySQL directly
docker-compose exec mysql mysql -u mfp_user -pmfp_password mfp_academy
```

## Persistent Storage

The following data is persisted:

- **MySQL Data**: Stored in Docker volume `mysql-data`
- **Application Storage**: Mounted from `./storage` directory

To backup your data:

```bash
# Backup MySQL database
docker-compose exec mysql mysqldump -u mfp_user -pmfp_password mfp_academy > backup.sql

# Restore MySQL database
docker-compose exec -T mysql mysql -u mfp_user -pmfp_password mfp_academy < backup.sql
```

## Services

The docker-compose setup includes:

1. **app**: Laravel application (nginx + php-fpm + queue worker)
2. **mysql**: MySQL 8.0 database
3. **phpmyadmin** (optional): Database management interface
4. **mailhog** (optional): Email testing tool

## Stopping the Application

```bash
# Stop services but keep data
docker-compose down

# Stop services and remove all data
docker-compose down -v
```

## GitHub Container Registry

The Docker image is automatically built and pushed to GitHub Container Registry (ghcr.io) on every push to the main/master branch.

### Pull the Latest Image

```bash
docker pull ghcr.io/oclab/mfp-academy:latest
```

### Available Tags

- `latest`: Latest build from the main/master branch
- `<branch-name>`: Build from specific branch
- `v*`: Tagged releases (e.g., v1.0.0)

## Building the Docker Image Manually

If you want to build and push the image manually:

```bash
# Build the image
docker build -t ghcr.io/oclab/mfp-academy:latest .

# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Push the image
docker push ghcr.io/oclab/mfp-academy:latest
```

## Troubleshooting

### Container won't start

Check the logs:
```bash
docker-compose logs app
```

### Database connection issues

Ensure MySQL is healthy:
```bash
docker-compose ps
docker-compose logs mysql
```

### Permission issues

Fix storage permissions:
```bash
docker-compose exec app chown -R www-data:www-data /var/www/html/storage
docker-compose exec app chmod -R 755 /var/www/html/storage
```

### Clear all caches

```bash
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear
docker-compose exec app php artisan view:clear
```

## Production Deployment

For production deployments:

1. Set `APP_ENV=production` and `APP_DEBUG=false`
2. Use strong passwords for database
3. Set proper `APP_URL`
4. Configure email settings
5. Set up SSL/TLS with a reverse proxy (nginx, Caddy, or Traefik)
6. Use Docker secrets or environment files for sensitive data
7. Set up regular database backups
8. Monitor logs and application health

Example production setup with Traefik:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.mfp-academy.rule=Host(`your-domain.com`)"
  - "traefik.http.routers.mfp-academy.entrypoints=websecure"
  - "traefik.http.routers.mfp-academy.tls.certresolver=letsencrypt"
```

## Development

For local development without Docker:

1. Install PHP 8.2+ and Composer
2. Install MySQL 8.0
3. Copy `.env.example` to `.env` and configure
4. Run `composer install`
5. Run `npm install && npm run dev`
6. Run `php artisan migrate`
7. Run `php artisan serve`

## Support

For issues and questions, please open an issue on the GitHub repository.

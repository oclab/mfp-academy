#!/bin/bash
set -e

echo "Starting MFP Academy Application..."

# Wait for MySQL to be ready
if [ "$DB_CONNECTION" = "mysql" ]; then
    echo "Waiting for MySQL to be ready..."
    until php artisan db:show 2>/dev/null; do
        echo "MySQL is unavailable - sleeping"
        sleep 2
    done
    echo "MySQL is ready!"
fi

# Run migrations if needed
if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
    echo "Running database migrations..."
    php artisan migrate --force --no-interaction
fi

# Cache configuration
echo "Caching configuration..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start supervisor
echo "Starting supervisord..."
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf

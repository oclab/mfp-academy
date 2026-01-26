#!/bin/bash
set -e

echo "Starting MFP Academy Application..."

# Wait for MySQL to be ready
if [ "$DB_CONNECTION" = "mysql" ]; then
    echo "Waiting for MySQL to be ready..."
    max_retries=30
    count=0
    until php artisan migrate:status 2>/dev/null || [ $count -eq $max_retries ]; do
        echo "MySQL is unavailable - sleeping (attempt $count/$max_retries)"
        sleep 2
        count=$((count + 1))
    done
    
    if [ $count -eq $max_retries ]; then
        echo "Warning: Could not connect to MySQL after $max_retries attempts"
    else
        echo "MySQL is ready!"
    fi
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

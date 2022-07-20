#!/bin/bash

[[ -f /var/www/html/.env ]] && source /var/www/html/.env

# When the directory is over-written by the host the vendor directory may nolonger exist
# We should fix this - but strictly only on dev
if [[ ! -d /var/www/html/vendor ]]; then
    if [[ $APP_ENV != "local" ]]; then
        echo "vendor Directory is missing - exiting"
        exit
    fi
    composer install
fi

if [[ -z $APP_KEY ]]; then
    if [[ $APP_ENV == "production" ]]; then
        echo "-- APP_KEY is missing or invalid - exiting"
        exit
    fi
    if ! [[ -f /var/www/html/.env ]]; then
        echo "APP_KEY=" > /var/www/html/.env
        echo "-- no .env found - creating template"
        sleep 1
    fi
    php artisan key:generate
fi

if [[ $APP_ENV == "production" ]]; then
    php artisan optimize &&
    php artisan event:cache &&
    php artisan view:cache || {
        echo "-- failed to build caches - exiting"
        exit
    }
fi
if [[ $APP_ENV == "local" ]]; then
    if ! [[ -d /var/www/html/vendor ]]; then
        composer install
    fi
    if ! [[ -f /var/www/html/.env ]]; then
        echo "APP_KEY=" > /var/www/html/.env
        echo "-- no .env found - creating template"
    fi
    php artisan key:generate
fi
php artisan storage:link
php artisan migrate --force || {
    echo "-- failed to handle DB migrations - exiting"
    [[ $APP_ENV == "production" ]] && exit
}

if [ $# -eq 0 ]; then
    exec /usr/local/bin/caddy run --config ${CADDY_PATH}
fi

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- php-fpm "$@"
fi

exec "$@"

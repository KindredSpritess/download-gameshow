ARG PHP_VERSION=8.1


FROM caddy:2-builder AS caddy-builder
RUN xcaddy build --with github.com/baldinof/caddy-supervisor


FROM php:${PHP_VERSION}-fpm AS base
RUN apt-get update \
  && apt-get install -y \
    libzip-dev \
  && apt-get clean -y\
  && rm -rf /var/lib/apt/lists/* \
  && docker-php-ext-install \
    opcache \
    pdo_mysql \
    zip \
  && docker-php-ext-configure zip \
  && docker-php-ext-install zip


FROM base as lando
ENV XDEBUG_MODE=
ENV APP_ENV=local
RUN pecl install \
  xdebug


FROM base as caddy-up
ARG FPM_CONF_SRC=https://gist.githubusercontent.com/DH-92/bd84c1ac6768f6908d3233f1ae4bbeb1/raw/1f97f1b8565824fc1e50ca8006f58b344a1f13ff/zz-docker.conf
ARG FPM_CONF_PATH=/usr/local/etc/php-fpm.d/zz-docker.conf
ARG CADDY_SRC=https://gist.githubusercontent.com/DH-92/bd84c1ac6768f6908d3233f1ae4bbeb1/raw/1f97f1b8565824fc1e50ca8006f58b344a1f13ff/Caddyfile
ARG CADDY_PATH=/etc/caddy/Caddyfile
ENV CADDY_PATH=$CADDY_PATH
ADD --chown=www-data:www-data "$CADDY_SRC" "$CADDY_PATH"
ADD --chown=www-data:www-data "$FPM_CONF_SRC" "$FPM_CONF_PATH"
COPY --from=caddy-builder /usr/bin/caddy /usr/local/bin/caddy
RUN caddy validate -config "$CADDY_PATH" \
  && chown www-data:www-data \
    /var/www/ \
    /var/run/
COPY --chown=www-data:www-data ./entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]


FROM caddy-up as dev
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
ENV XDEBUG_MODE=
ENV APP_ENV=local
RUN pecl install \
  xdebug
USER www-data


FROM base AS start-composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY composer.json composer.lock ./
# ARG NOVA_USERNAME=webmaster@centreforceit.com.au
# ARG NOVA_LICENSE_KEY
# RUN [[ -z $NOVA_LICENSE_KEY ]] \
#   && echo "Please acquire the nova license key: " \
#   && "https://nova.laravel.com/licenses/95fcc60f-1b1d-4f1c-8277-568e5caf7d1c" \
#   && exit 1
# RUN composer config --auth http-basic.nova.laravel.com "${NOVA_USERNAME}" "${NOVA_LICENSE_KEY}" \
#   && chown www-data:www-data auth.json \
#   && chmod 644 auth.json \
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-plugins --no-interaction


FROM caddy-up AS post-composer
COPY --chown=www-data:www-data . .
COPY --from=start-composer /var/www/html/vendor vendor
RUN php artisan package:discover --ansi


FROM post-composer AS final
ARG APP_KEY=""
ENV APP_KEY=$APP_KEY
ARG BRANCH=local
ENV BRANCH=$BRANCH
ARG SHA=000
ENV SHA=$SHA
ENV APP_ENV=production
USER www-data

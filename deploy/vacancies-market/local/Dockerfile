FROM php:8.5-fpm-alpine

RUN apk add --no-cache \
    postgresql-dev \
    nginx \
    supervisor \
    curl \
    zip \
    libzip-dev \
    git \
    unzip \
    oniguruma-dev \
    bash

RUN docker-php-ext-install \
    pdo_pgsql \
    pgsql \
    zip \
    mbstring \
    bcmath

COPY --from=composer:2.10.1 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

COPY . .

RUN mkdir -p storage/framework/{sessions,views,cache} \
    && mkdir -p storage/logs \
    && mkdir -p storage/app/public \
    && mkdir -p bootstrap/cache \
    && mkdir -p public

RUN composer install --no-interaction --optimize-autoloader

RUN chown -R www-data:www-data /var/www \
    && chmod -R 775 /var/www/storage \
    && chmod -R 775 /var/www/bootstrap/cache

COPY deploy/nginx.conf /etc/nginx/nginx.conf

EXPOSE 8000

CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]
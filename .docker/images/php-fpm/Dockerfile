# Use latest php:fpm as base image.
FROM php:fpm

# Run apt update and upgrade.
RUN apt-get update && apt-get -y upgrade

# Install required packages.
RUN apt-get -y install curl git libcurl3-dev libonig-dev libpng-dev libxml2-dev libzip-dev nano zip

# Installing additional PHP modules
RUN docker-php-ext-install curl gd mbstring pdo_mysql xml

# Install Composer.
COPY --from=composer:2.7.7 /usr/bin/composer /usr/local/bin/composer

# Set working directory.
WORKDIR /var/www/site
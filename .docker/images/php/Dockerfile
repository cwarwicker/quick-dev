############################## BASE PHP STAGE ########################################
ARG PHP_VERSION=8.3.12

# Use latest php:fpm as base image.
FROM php:${PHP_VERSION}-fpm AS base

# Run apt update and upgrade.
RUN apt-get update && apt-get -y upgrade

# Install required packages.
RUN apt-get -y install curl git libcurl3-dev libonig-dev libpng-dev libpq-dev libxml2-dev libzip-dev nano zip

# Installing additional PHP modules
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql
RUN docker-php-ext-install curl dom gd intl mbstring mysqli pdo_mysql pgsql pdo_pgsql xml zip

# Redis seems to need to be done via pecl instead of ext install.
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer.
COPY --from=composer:2.7.7 /usr/bin/composer /usr/local/bin/composer

# Set working directory.
WORKDIR /app

############################## LARAVEL STAGE ########################################

ARG PHP_VERSION
FROM base AS laravel

############################## MOODLE STAGE ########################################

ARG PHP_VERSION
FROM base AS moodle

# Install NVM and NodeJS
RUN apt-get install -y nodejs npm

ENV NVM_DIR=/usr/local/nvm
ENV NODE_VERSION=v20.17.0
ENV NODE_PATH=$NVM_DIR/versions/node/$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/$NODE_VERSION/bin:$PATH

RUN mkdir -p $NVM_DIR && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use --delete-prefix $NODE_VERSION"

# Create sitedata directory.
RUN mkdir -p /var/www/data && chmod 0777 /var/www/data

# Add the .ini files with the directives we need.
ADD ./moodle/php.ini /usr/local/etc/php/conf.d/custom.ini
ADD ./moodle/cli.php.ini /usr/local/php/conf.d/custom-cli.ini

############################## END ########################################

############################## BASE PHP STAGE ########################################
ARG PHP_VERSION=8.3.12

# Use latest php:fpm as base image.
FROM php:${PHP_VERSION}-fpm AS base

# Run apt update and upgrade.
RUN apt-get update && apt-get -y upgrade

# Install required packages.
RUN apt-get -y install curl git ghostscript libcurl3-dev libfreetype6-dev libjpeg-dev libonig-dev libpng-dev libpq-dev libxml2-dev libxslt-dev libzip-dev nano nodejs npm zip

# Installing additional PHP modules
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql
RUN docker-php-ext-configure gd --with-jpeg --with-freetype
RUN docker-php-ext-install curl dom gd intl mbstring mysqli pdo_mysql pgsql pdo_pgsql soap xml xsl zip

# Redis seems to need to be done via pecl instead of ext install.
RUN pecl install redis && docker-php-ext-enable redis
RUN pecl install xhprof && docker-php-ext-enable xhprof

# Install Composer.
COPY --from=composer:2.7.7 /usr/bin/composer /usr/local/bin/composer

# Install node version.
ENV NVM_DIR=/usr/local/nvm
ENV NODE_VERSION=v22.11
ENV NODE_PATH=$NVM_DIR/versions/node/$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/$NODE_VERSION/bin:$PATH
RUN mkdir -p $NVM_DIR && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use --delete-prefix $NODE_VERSION"

# Set working directory.
WORKDIR /app

############################## LARAVEL STAGE ########################################

ARG PHP_VERSION
FROM base AS laravel
RUN composer global require laravel/installer
ENV PATH="/root/.config/composer/vendor/bin:${PATH}"


############################## MOODLE STAGE ########################################

ARG PHP_VERSION
FROM base AS moodle

RUN apt-get install -y locales-all
RUN pecl install excimer && docker-php-ext-enable excimer

# Create sitedata directory.
RUN mkdir -p /var/www/data && chmod 0777 /var/www/data

# Add the .ini files with the directives we need.
ADD ./moodle/php.ini /usr/local/etc/php/conf.d/custom.ini
ADD ./moodle/cli.php.ini /usr/local/php/conf.d/custom-cli.ini

# Clone the moodle-browser-config plugin for behat.
RUN git clone https://github.com/andrewnicols/moodle-browser-config.git /var/www/moodle-browser-config

############################## TOTARA STAGE ########################################

ARG PHP_VERSION
FROM moodle AS totara

############################## MAHARA STAGE ########################################

ARG PHP_VERSION
FROM base as mahara

RUN apt-get install -y locales-all

# Create sitedata directory.
RUN mkdir -p /var/www/data && chmod 0777 /var/www/data

# Add the .ini files with the directives we need. Using the same ones as Moodle here.
ADD ./moodle/php.ini /usr/local/etc/php/conf.d/custom.ini
ADD ./moodle/cli.php.ini /usr/local/php/conf.d/custom-cli.ini

############################## END ########################################

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PHP_VERSION=8.2

# Run apt update and upgrade.
RUN apt-get update && apt-get -y upgrade

# Add required repositories.
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:ondrej/php

# Install required packages.
RUN apt-get -y install apache2 curl nano git \
    php$PHP_VERSION \
    php$PHP_VERSION-cli \
    php$PHP_VERSION-curl \
    php$PHP_VERSION-dom \
    php$PHP_VERSION-fileinfo \
    php$PHP_VERSION-gd \
    php$PHP_VERSION-intl \
    php$PHP_VERSION-mbstring \
    php$PHP_VERSION-mysql \
    php$PHP_VERSION-mysqli \
    php$PHP_VERSION-redis \
    php$PHP_VERSION-xdebug \
    php$PHP_VERSION-xml \
    php$PHP_VERSION-zip \
    phpunit libapache2-mod-php$PHP_VERSION

# Enable PHP and Apache rewrite module.
RUN a2enmod php$PHP_VERSION
RUN a2enmod rewrite

# Set some envionrment variables.
ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV APACHE_PID_FILE=/var/run/apache2.pid

# Expose port 80 to run apache on.
EXPOSE 80

# Copy over some config files to the container.
ADD apache.conf /etc/apache2/sites-enabled/000-default.conf
ADD php.ini /etc/php/$PHP_VERSION/apache2/conf.d/custom.ini
ADD cli.php.ini /etc/php/$PHP_VERSION/cli/conf.d/custom.ini

# Install Composer.
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Create sitedata directory.
RUN mkdir -p /var/www/data && chown www-data /var/www/data && chgrp www-data /var/www/data && chmod 0777 /var/www/data

# Start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND
FROM ubuntu:24.04

# Make everything non-interactive.
ENV DEBIAN_FRONTEND=noninteractive

# Run apt update and upgrade.
RUN apt-get update && apt-get -y upgrade

# Add required repositories.
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:ondrej/php

# Install required packages.
RUN apt-get -y install apache2 curl nano git \
    php8.2-common php8.2-cli php8.2-mbstring php8.2-mysql php8.2-xdebug php8.2-curl php8.2-gd php8.2-zip php8.2-xml php8.2-dom php8.2-redis \
    phpunit libapache2-mod-php8.2

# Enable PHP and Apache rewrite module.
RUN a2enmod php8.2
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
ADD php.ini /etc/php/8.2/apache2/conf.d/99-custom.ini

# Install Composer.
COPY --from=composer:2.7.7 /usr/bin/composer /usr/local/bin/composer

# Set working directory.
WORKDIR /var/www/site

# Start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND
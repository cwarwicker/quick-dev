# Use base php image.
FROM quick-dev:php

RUN apt-get install -y nodejs npm

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash

RUN nvm install 20.11

# Installing additional PHP modules needed by moodle.
RUN docker-php-ext-install curl dom gd intl mbstring mysqli pdo_mysql xml zip

# Create sitedata directory.
RUN mkdir -p /var/www/data && chmod 0777 /var/www/data

# Add the .ini files with the directives we need.
ADD php.ini /usr/local/etc/php/conf.d/custom.ini
ADD cli.php.ini /usr/local/php/conf.d/custom-cli.ini

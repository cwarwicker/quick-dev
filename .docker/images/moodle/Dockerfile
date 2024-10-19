# Use base php image.
#FROM quick-dev:php
# testing out 8.4
FROM quick-dev:php-8.4

RUN apt-get install -y nodejs npm

# Install NVM and NodeJS
ENV NVM_DIR=/usr/local/nvm
ENV NODE_VERSION=v20.17.0

RUN mkdir -p $NVM_DIR && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use --delete-prefix $NODE_VERSION"

ENV NODE_PATH=$NVM_DIR/versions/node/$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/$NODE_VERSION/bin:$PATH

# Installing additional PHP modules needed by moodle.
RUN docker-php-ext-install curl dom gd intl mbstring mysqli pdo_mysql xml zip

# Create sitedata directory.
RUN mkdir -p /var/www/data && chmod 0777 /var/www/data

# Add the .ini files with the directives we need.
ADD php.ini /usr/local/etc/php/conf.d/custom.ini
ADD cli.php.ini /usr/local/php/conf.d/custom-cli.ini

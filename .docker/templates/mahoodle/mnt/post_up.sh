#!/usr/bin/bash
# Moodle
echo "===== Installing composer packages"
cd /app/moodle && composer install

# Mahara
echo "===== Installing composer packages"
cd /app/mahara && composer install

echo "==== Installing gulp"
cd /app/mahara && npm install -g gulp

echo "==== Creating symlink for nvm"
ln -s /usr/local/nvm ${HOME}/.nvm

echo "===== Building CSS files"
cd /app/mahara && make css
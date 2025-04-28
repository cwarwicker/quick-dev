#!/usr/bin/bash
echo "===== Installing composer packages"
composer install

echo "==== Installing gulp"
npm install -g gulp

echo "==== Creating symlink for nvm"
ln -s /usr/local/nvm ${HOME}/.nvm

echo "===== Building CSS files"
make css
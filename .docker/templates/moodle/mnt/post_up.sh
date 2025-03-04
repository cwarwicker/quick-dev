#!/usr/bin/bash
echo "===== Applying customisations to moodle-browser-config library"
cp /mnt/moodle-browser-config/config.php /var/www/moodle-browser-config/
cp /mnt/moodle-browser-config/localprofiles.php /var/www/moodle-browser-config/

echo "===== Adding debugging packages"
composer require --dev symfony/var-dumper -W
composer require --dev spatie/ray -W
composer require --dev inspector-apm/inspector-php -W
composer require --dev spiral-packages/profiler -W

echo "===== Installing composer packages"
composer install
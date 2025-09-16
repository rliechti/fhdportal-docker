#!/bin/bash

# Navigate to the application directory (adjust this path as needed)
cd /var/www/fhd-portal/htdocs/api

# Run Composer install (or update)
echo $COMPOSER_ALLOW_SUPERUSER=1
composer install --no-interaction --no-plugins --no-scripts --prefer-dist
composer require symfony/runtime

# Start PHP-FPM
touch /usr/local/log/php_fpm_www-error_log
chown www-data:www-data /usr/local/log/php_fpm_www-error_log
chmod 644 /usr/local/log/php_fpm_www-error_log

# Fix chmod permission on Symfony dirs
[ -d /var/www/fhd-portal/htdocs/api/var/cache/prod ] && chmod 777 -R /var/www/fhd-portal/htdocs/api/var/cache/prod
[ -d /var/www/fhd-portal/htdocs/api/var/log ] && chmod 777 -R /var/www/fhd-portal/htdocs/api/var/log

# Start CRON
service cron start

exec php-fpm

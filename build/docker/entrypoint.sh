#!/bin/sh
set -e
cd /var/www/html

npm install
npx eleventy
composer install

CHOKIDAR_USEPOLLING=true npx eleventy --watch &

exec apache2-foreground

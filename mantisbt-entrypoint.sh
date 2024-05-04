#!/bin/bash

set -eo pipefail

# Configure the timezone for this image
ln -sf /usr/share/zoneinfo/$MANTIS_TIMEZONE /etc/localtime
echo date.timezone = "$MANTIS_TIMEZONE" > /usr/local/etc/php/php.ini
echo upload_max_filesize = "$PHP_MAX_UPLOAD_SIZE" >> /usr/local/etc/php/php.ini
echo 'display_errors = Off' >> /usr/local/etc/php/php.ini
echo 'display_startup_errors = Off' >> /usr/local/etc/php/php.ini

# If MANTIS_ENABLE_ADMIN is set to , then enable 'admin' folder
test -d admin && chmod -rx admin && mv admin .admin

if [ ! -z "$MANTIS_ENABLE_ADMIN" ] && [ "$MANTIS_ENABLE_ADMIN" -ne "0" ]; then
  test -d .admin && mv .admin admin && chmod +rx admin
fi

apache2-foreground

#!/bin/sh

set -e

# Timezone and PHP settings
ln -sf "/usr/share/zoneinfo/$MANTIS_TIMEZONE" /etc/localtime
cat > "$PHP_INI_DIR/conf.d/zz-mantis.ini" <<EOF
date.timezone = "$MANTIS_TIMEZONE"
upload_max_filesize = "$PHP_MAX_UPLOAD_SIZE"
display_errors = Off
display_startup_errors = Off
log_errors = On
register_argc_argv = Off
expose_php = Off
EOF

# Hide 'admin' folder unless MANTIS_ENABLE_ADMIN is set and not 0
test -d admin && chmod -rx admin && mv admin .admin

if [ -n "$MANTIS_ENABLE_ADMIN" ] && [ "$MANTIS_ENABLE_ADMIN" -ne "0" ]; then
  test -d .admin && mv .admin admin && chmod +rx admin
fi

# Stale pid after container restart
rm -f /run/apache2/httpd.pid
exec httpd -DFOREGROUND

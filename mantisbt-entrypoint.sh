#!/bin/bash

set -eo pipefail

# If MANTIS_ENABLE_ADMIN is set to , then enable 'admin' folder
test -d admin && chmod -rx admin && mv admin .admin

if [ ! -z "$MANTIS_ENABLE_ADMIN" ] && [ "$MANTIS_ENABLE_ADMIN" -ne "0" ]; then
  test -d .admin && mv .admin admin && chmod +rx admin
fi

apache2-foreground

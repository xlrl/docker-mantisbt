#
# Dockerfile for mantisbt, Alpine with distro PHP (no compiler)
#

ARG MANTIS_VER=2.29.0
ARG MANTIS_SHA512=1741f9e985bb2b030a04972dd6cce57641e513bc36ee27e38ba4e0e5d079f23f62cc7ae464af37e1baee46fc04bdb5e8d30348a381eec2cf940c64b9599d1e4b

# Fetch and verify the tarball once, natively on the build host
FROM --platform=$BUILDPLATFORM alpine:3.24 AS fetch

ARG MANTIS_VER
ARG MANTIS_SHA512
ARG MANTIS_URL=https://downloads.sourceforge.net/project/mantisbt/mantis-stable/${MANTIS_VER}/mantisbt-${MANTIS_VER}.tar.gz

RUN set -xe \
    && apk add --no-cache curl \
    && curl -fSL "${MANTIS_URL}" -o /mantisbt.tar.gz \
    && echo "${MANTIS_SHA512}  /mantisbt.tar.gz" | sha512sum -c \
    && mkdir /src \
    && tar -xz --strip-components=1 -C /src -f /mantisbt.tar.gz \
    && rm -rf /src/doc

FROM alpine:3.24

ENV PHP_INI_DIR=/etc/php85

# Prebuilt PHP and extensions
RUN apk add --no-cache \
        apache2 tzdata \
        php85 php85-apache2 \
        php85-ctype php85-curl php85-dom php85-fileinfo php85-gd php85-iconv \
        php85-ldap php85-mbstring php85-mysqli php85-pgsql php85-session \
        php85-simplexml php85-soap php85-tokenizer php85-xml php85-xmlreader \
        php85-xmlwriter

# Same uid/gid as the Debian image (33), keeps existing volumes working
RUN set -xe \
    && delgroup www-data \
    && addgroup -S -g 33 www-data \
    && adduser -S -D -H -u 33 -G www-data -h /var/www -s /sbin/nologin www-data

# Apache: rewrite, www-data, /var/www/html, logs to stdout/stderr, hide version
RUN set -xe \
    && sed -i \
        -e 's/^#\(LoadModule rewrite_module\)/\1/' \
        -e 's/^User apache/User www-data/' \
        -e 's/^Group apache/Group www-data/' \
        -e 's#/var/www/localhost/htdocs#/var/www/html#g' \
        -e 's#^ErrorLog .*#ErrorLog /dev/stderr#' \
        -e 's#^\(\s*CustomLog\) logs/access.log combined#\1 /dev/stdout combined#' \
        -e 's/^ServerTokens .*/ServerTokens Prod/' \
        -e 's/^ServerSignature .*/ServerSignature Off/' \
        /etc/apache2/httpd.conf \
    && printf '%s\n' \
        'ServerName localhost' \
        '<Directory "/var/www/html">' \
        '    AllowOverride All' \
        '</Directory>' \
        > /etc/apache2/conf.d/mantis.conf \
    && mkdir -p /var/www/html

ARG MANTIS_VER
ENV MANTIS_VER=${MANTIS_VER}
ENV MANTIS_TIMEZONE=Europe/Berlin
ENV PHP_MAX_UPLOAD_SIZE="5M"

WORKDIR /var/www/html

COPY --from=fetch --chown=www-data:www-data /src/ /var/www/html/

COPY mantisbt-entrypoint.sh /usr/local/bin/mantisbt-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/mantisbt-entrypoint.sh"]

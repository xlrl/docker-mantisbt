#
# Dockerfile for mantisbt, Alpine with distro PHP (no compiler)
#

FROM alpine:3.24

ENV PHP_INI_DIR=/etc/php85

# Prebuilt PHP and extensions
RUN apk add --no-cache \
        apache2 tzdata curl \
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

ENV MANTIS_VER=2.28.4
ENV MANTIS_SHA512=95968b0e6c3d66a14aa575ddece1b25110b830e54571f8650f619e2f3a9c82a8939605b72b1f4df6448136156cd2f80d5a9831b214104bdfb64b06790de2c0a0
ENV MANTIS_URL=https://downloads.sourceforge.net/project/mantisbt/mantis-stable/${MANTIS_VER}/mantisbt-${MANTIS_VER}.tar.gz
ENV MANTIS_FILE=mantisbt.tar.gz
ENV MANTIS_TIMEZONE=Europe/Berlin
ENV PHP_MAX_UPLOAD_SIZE="5M"

WORKDIR /var/www/html

RUN set -xe \
    && curl -fSL ${MANTIS_URL} -o ${MANTIS_FILE} \
    && echo "${MANTIS_SHA512}  ${MANTIS_FILE}" | sha512sum -c \
    && tar -xz --strip-components=1 -f ${MANTIS_FILE} \
    && rm ${MANTIS_FILE} \
    && rm -rf doc \
    && chown -R www-data:www-data .

COPY mantisbt-entrypoint.sh /usr/local/bin/mantisbt-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/mantisbt-entrypoint.sh"]

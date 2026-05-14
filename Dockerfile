#
# Dockerfile for mantisbt
#

FROM php:8.5.6-apache

RUN a2enmod rewrite

RUN set -xe \
    && apt-get update \
    && apt-get install -y libpng-dev libjpeg-dev libpq-dev libxml2-dev libldap-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install gd mysqli pgsql soap ldap \
    && rm -rf /var/lib/apt/lists/*

ENV MANTIS_VER=2.28.3
ENV MANTIS_SHA512=589e2306591934a8910219e6e0a3070a27051ac4d12ccbcb222e5e0e5216786f17a0937e2e2d94a0d633cbc40436b91634331ede477dac1f4c7ba459a04c7b5e
ENV MANTIS_URL=https://downloads.sourceforge.net/project/mantisbt/mantis-stable/${MANTIS_VER}/mantisbt-${MANTIS_VER}.tar.gz
ENV MANTIS_FILE=mantisbt.tar.gz
ENV MANTIS_TIMEZONE=Europe/Berlin
ENV PHP_MAX_UPLOAD_SIZE="2M"

RUN set -xe \
    && curl -fSL ${MANTIS_URL} -o ${MANTIS_FILE} \
    && sha512sum ${MANTIS_FILE} \
    && echo "${MANTIS_SHA512}  ${MANTIS_FILE}" | sha512sum -c \
    && tar -xz --strip-components=1 -f ${MANTIS_FILE} \
    && rm ${MANTIS_FILE} \
    && chown -R www-data:www-data .

COPY mantisbt-entrypoint.sh /usr/local/bin/mantisbt-entrypoint.sh

WORKDIR /var/www/html

ENTRYPOINT /usr/local/bin/mantisbt-entrypoint.sh

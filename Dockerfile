#
# Dockerfile for mantisbt
#

FROM php:8.3.12-apache

RUN a2enmod rewrite

RUN set -xe \
    && apt-get update \
    && apt-get install -y libpng-dev libjpeg-dev libpq-dev libxml2-dev libldap-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install gd mysqli pgsql soap ldap \
    && rm -rf /var/lib/apt/lists/*

ENV MANTIS_VER 2.27.0
ENV MANTIS_SHA512 988e2d267c2d02c0aebe475c3c58ea338f1cf9b56130ab5f18a02b50acd398a74544d31f4198e52a011a8ad02cf8f975c72ad9e373e10a7229309b433d8c9c05
ENV MANTIS_URL https://downloads.sourceforge.net/project/mantisbt/mantis-stable/${MANTIS_VER}/mantisbt-${MANTIS_VER}.tar.gz
ENV MANTIS_FILE mantisbt.tar.gz
ENV MANTIS_TIMEZONE Europe/Berlin
ENV PHP_MAX_UPLOAD_SIZE "2M"

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

#
# Dockerfile for mantisbt
#

FROM php:8.5.7-apache

RUN a2enmod rewrite

RUN set -xe \
    && apt-get update \
    && apt-get install -y libpng-dev libjpeg-dev libpq-dev libxml2-dev libldap-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install gd mysqli pgsql soap ldap \
    && rm -rf /var/lib/apt/lists/*

ENV MANTIS_VER=2.28.4
ENV MANTIS_SHA512=95968b0e6c3d66a14aa575ddece1b25110b830e54571f8650f619e2f3a9c82a8939605b72b1f4df6448136156cd2f80d5a9831b214104bdfb64b06790de2c0a0
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

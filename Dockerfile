#
# Dockerfile for mantisbt
#

FROM php:apache

RUN a2enmod rewrite

RUN set -xe \
    && apt-get update \
    && apt-get install -y libpng-dev libjpeg-dev libpq-dev libxml2-dev libldap-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install gd mysqli pgsql soap ldap \
    && rm -rf /var/lib/apt/lists/*

ENV MANTIS_VER 2.25.6
ENV MANTIS_SHA512 17bfc75629c8b172a197fb2424ebedfddb5ca0759793ddda98b2c4d60c96a71f88a252059db81a432884a5db1955da0c094bbbc0b20567e326b2afa5f6643319
ENV MANTIS_URL https://downloads.sourceforge.net/project/mantisbt/mantis-stable/${MANTIS_VER}/mantisbt-${MANTIS_VER}.tar.gz
ENV MANTIS_FILE mantisbt.tar.gz
ENV MANTIS_TIMEZONE Europe/Berlin

RUN set -xe \
    && curl -fSL ${MANTIS_URL} -o ${MANTIS_FILE} \
    && sha512sum ${MANTIS_FILE} \
    && echo "${MANTIS_SHA512}  ${MANTIS_FILE}" | sha512sum -c \
    && tar -xz --strip-components=1 -f ${MANTIS_FILE} \
    && rm ${MANTIS_FILE} \
    && chown -R www-data:www-data .

RUN set -xe \
    && ln -sf /usr/share/zoneinfo/${MANTIS_TIMEZONE} /etc/localtime \
    && echo 'date.timezone = "${MANTIS_TIMEZONE}"' > /usr/local/etc/php/php.ini

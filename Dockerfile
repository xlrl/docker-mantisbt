#
# Dockerfile for mantisbt
#

FROM php:apache
MAINTAINER XelaRellum <XelaRellum@web.de>

RUN a2enmod rewrite

RUN set -xe \
    && apt-get update \
    && apt-get install -y libpng-dev libjpeg-dev libpq-dev libxml2-dev libldap-dev \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install gd mysqli pgsql soap ldap \
    && rm -rf /var/lib/apt/lists/*

ENV MANTIS_VER 2.25.1
ENV MANTIS_SHA512 f8ee2d051a8b10d3dadd6115ba5420533d797748d987c7044cfc0a2e0849cb54f7664aa064a05c56f2084f7929396567e27a6207b4f6d1557504a0204eae577f
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

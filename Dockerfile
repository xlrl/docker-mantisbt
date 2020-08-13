#
# Dockerfile for mantisbt
#

FROM php:apache
MAINTAINER XelaRellum <XelaRellum@web.de>

RUN a2enmod rewrite

RUN set -xe \
    && apt-get update \
    && apt-get install -y libpng-dev libjpeg-dev libpq-dev libxml2-dev \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install gd mysqli pgsql soap \
    && rm -rf /var/lib/apt/lists/*

ENV MANTIS_VER 2.24.2
ENV MANTIS_SHA1 81d339aa60b8878b5398d7f7ef1f66151877742fac22944e67394ac087c1f4f2c8d5f270127dacc59cbead1a478a6698380b113abbc6a38177e87cc78cd0acd8
ENV MANTIS_URL http://jaist.dl.sourceforge.net/project/mantisbt/mantis-stable/${MANTIS_VER}/mantisbt-${MANTIS_VER}.tar.gz
ENV MANTIS_FILE mantisbt.tar.gz
ENV MANTIS_TIMEZONE Europe/Berlin

RUN set -xe \
    && curl -fSL ${MANTIS_URL} -o ${MANTIS_FILE} \
    && echo "${MANTIS_SHA1}  ${MANTIS_FILE}" | sha512sum -c \
    && tar -xz --strip-components=1 -f ${MANTIS_FILE} \
    && rm ${MANTIS_FILE} \
    && chown -R www-data:www-data .

RUN set -xe \
    && ln -sf /usr/share/zoneinfo/${MANTIS_TIMEZONE} /etc/localtime \
    && echo 'date.timezone = "${MANTIS_TIMEZONE}"' > /usr/local/etc/php/php.ini


ENV DPE_SHA1 d59ca12d89616c1bccb7769df5b9b97fb5a9a98c
ENV DPE docker-php-entrypoint
ENV NDPE new-docker-php-entrypoint
ENV ODPE old-docker-php-entrypoint

COPY admin-disable-snippet /usr/local/bin

RUN set -xe \
    && cd /usr/local/bin \
    && echo "${DPE_SHA1} ${DPE}" | sha1sum -c || (echo "Upstream ${DPE} files has changed, verify this script." && exit 1 ) \
    && head -n-1 $DPE > $NDPE \
    && cat admin-disable-snippet >> $NDPE \
    && tail -n1 $DPE >> $NDPE \
    && mv $DPE $ODPE \
    && mv $NDPE $DPE \
    && chmod 775 $DPE


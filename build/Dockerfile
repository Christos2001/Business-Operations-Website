FROM php:8.3-apache

RUN apt-get update && apt-get install -y \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    python3 \
    python3-pip \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --enable-gd --with-jpeg \
    && docker-php-ext-install mysqli gd exif

COPY docker/php/app.ini /usr/local/etc/php/conf.d/99-app.ini

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY docker/gb-requirements.txt /tmp/gb-requirements.txt
RUN pip3 install --break-system-packages --no-cache-dir -r /tmp/gb-requirements.txt \
    && rm /tmp/gb-requirements.txt

ENV APACHE_DOCUMENT_ROOT=/var/www/html/src
RUN sed -ri -e 's!/var/www/html!/var/www/html/src!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/html!/var/www/html/src!g' /etc/apache2/apache2.conf \
    && sed -ri -e 's!/var/www/html!/var/www/html/src!g' /etc/apache2/conf-available/*.conf \
    && a2disconf javascript-common || true

COPY docker/apache/html-alias.conf /etc/apache2/conf-available/html-alias.conf
RUN a2enmod alias && a2enconf html-alias

WORKDIR /var/www/html

CMD ["/bin/sh", "/var/www/html/docker/entrypoint.sh"]

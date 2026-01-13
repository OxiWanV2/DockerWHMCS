ARG PHP_VERSION=8.1
FROM php:${PHP_VERSION}-apache

ENV PHP_MEMORY_LIMIT=256M \
    PHP_UPLOAD_MAX_FILESIZE=64M \
    PHP_POST_MAX_SIZE=64M \
    PHP_MAX_EXECUTION_TIME=300 \
    PHP_MAX_INPUT_VARS=5000 \
    PHP_TIMEZONE=Europe/Paris \
    APACHE_PORT=8080 \
    WHMCS_CRON_ENABLED=false \
    WHMCS_CRON_SCHEDULE="*/5 * * * *" \
    WHMCS_CRON_DAILY_ENABLED=false \
    WHMCS_CRON_DAILY_HOUR=9 \
    WHMCS_CRON_DAILY_MINUTE=0

LABEL org.opencontainers.image.source="https://github.com/OxiWanV2/DockerWHMCS"
LABEL org.opencontainers.image.description="Image Docker pour héberger WHMCS - Support PHP 7.4, 8.1, 8.2, 8.3"

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    libicu-dev \
    libonig-dev \
    libxml2-dev \
    unzip \
    git \
    cron \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_mysql \
    mysqli \
    curl \
    gd \
    mbstring \
    xml \
    zip \
    intl \
    opcache \
    bcmath \
    soap \
    sockets

RUN set -eux; \
    PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;"); \
    cd /tmp; \
    curl -fsSL -o ioncube.tar.gz https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz; \
    tar -xzf ioncube.tar.gz; \
    LOADER_FILE="ioncube/ioncube_loader_lin_${PHP_VERSION}.so"; \
    if [ ! -f "$LOADER_FILE" ]; then \
        echo "ERROR: IonCube loader non disponible pour PHP ${PHP_VERSION}"; \
        exit 1; \
    fi; \
    EXT_DIR=$(php-config --extension-dir); \
    cp "$LOADER_FILE" "${EXT_DIR}/ioncube_loader.so"; \
    echo "zend_extension=ioncube_loader.so" > /usr/local/etc/php/conf.d/00-ioncube.ini; \
    rm -rf /tmp/ioncube*; \
    php -v | grep -i ioncube || exit 1

RUN { \
    echo "memory_limit = 256M"; \
    echo "upload_max_filesize = 64M"; \
    echo "post_max_size = 64M"; \
    echo "max_execution_time = 300"; \
    echo "max_input_vars = 5000"; \
    echo "date.timezone = Europe/Paris"; \
    } > /usr/local/etc/php/conf.d/whmcs-defaults.ini

RUN a2enmod rewrite \
    && echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername \
    && echo "<Directory \"/var/www/html\">" > /etc/apache2/conf-available/htaccess.conf \
    && echo "  AllowOverride All" >> /etc/apache2/conf-available/htaccess.conf \
    && echo "</Directory>" >> /etc/apache2/conf-available/htaccess.conf \
    && a2enconf htaccess

RUN echo "Listen 8080" > /etc/apache2/ports.conf \
    && sed -i "s/:80>/:8080>/g" /etc/apache2/sites-available/000-default.conf

RUN mkdir -p /var/www/html/attachments \
    /var/www/html/downloads \
    /var/www/html/templates_c \
    && touch /var/www/html/configuration.php \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/attachments \
    /var/www/html/downloads \
    /var/www/html/templates_c \
    && chmod 664 /var/www/html/configuration.php

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8080

WORKDIR /var/www/html

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
#!/bin/bash
set -e

if [ -n "$PHP_MEMORY_LIMIT" ] || [ -n "$PHP_TIMEZONE" ]; then
    cat > /usr/local/etc/php/conf.d/whmcs-runtime.ini <<EOF
memory_limit = ${PHP_MEMORY_LIMIT}
upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}
post_max_size = ${PHP_POST_MAX_SIZE}
max_execution_time = ${PHP_MAX_EXECUTION_TIME}
max_input_vars = ${PHP_MAX_INPUT_VARS}
date.timezone = ${PHP_TIMEZONE}
EOF
fi

if [ "$APACHE_PORT" != "8080" ]; then
    echo "Listen ${APACHE_PORT}" > /etc/apache2/ports.conf
    sed -i "s/:8080>/:8080>/g" /etc/apache2/sites-available/000-default.conf
fi

chown -R www-data:www-data /var/www/html 2>/dev/null || true
chmod -R 775 /var/www/html/attachments /var/www/html/downloads /var/www/html/templates_c 2>/dev/null || true

if [ -f /var/www/html/configuration.php ]; then
    chmod 664 /var/www/html/configuration.php
fi

if [ -f /var/www/html/.htaccess ]; then
    chmod 664 /var/www/html/.htaccess
fi

if [ -d /var/www/html/crons ]; then
    chmod 755 /var/www/html/crons
fi

if [ -f /var/www/html/crons/cron.php ]; then
    echo "Exécution initiale du cron WHMCS..."
    su -s /bin/bash www-data -c "/usr/local/bin/php -q /var/www/html/crons/cron.php" >> /tmp/whmcs_cron_init.log 2>&1 || true
fi

if [ "$WHMCS_CRON_ENABLED" = "true" ] || [ "$WHMCS_CRON_DAILY_ENABLED" = "true" ]; then
    echo "SHELL=/bin/sh" > /etc/cron.d/whmcs-cron
    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" >> /etc/cron.d/whmcs-cron
    echo "" >> /etc/cron.d/whmcs-cron
    
    if [ "$WHMCS_CRON_ENABLED" = "true" ]; then
        echo "${WHMCS_CRON_SCHEDULE} www-data /usr/local/bin/php -q /var/www/html/crons/cron.php >> /var/log/whmcs_cron.log 2>&1" >> /etc/cron.d/whmcs-cron
    fi
    
    if [ "$WHMCS_CRON_DAILY_ENABLED" = "true" ]; then
        echo "${WHMCS_CRON_DAILY_MINUTE} ${WHMCS_CRON_DAILY_HOUR} * * * www-data /usr/local/bin/php -q /var/www/html/crons/cron.php daily >> /var/log/whmcs_cron_daily.log 2>&1" >> /etc/cron.d/whmcs-cron
    fi
    
    chmod 0644 /etc/cron.d/whmcs-cron
    touch /var/log/whmcs_cron.log /var/log/whmcs_cron_daily.log
    echo "✓ Cron configuré"
fi

exec "$@"
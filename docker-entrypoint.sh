#!/bin/bash
set -e

cat > /usr/local/etc/php/conf.d/whmcs.ini <<EOF
memory_limit = ${PHP_MEMORY_LIMIT}
upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}
post_max_size = ${PHP_POST_MAX_SIZE}
max_execution_time = ${PHP_MAX_EXECUTION_TIME}
max_input_vars = ${PHP_MAX_INPUT_VARS}
date.timezone = ${PHP_TIMEZONE}
EOF

echo "Listen ${APACHE_PORT}" > /etc/apache2/ports.conf
sed -i "s/:80>/:${APACHE_PORT}>/g" /etc/apache2/sites-available/000-default.conf

chown -R www-data:www-data /var/www/html/attachments /var/www/html/downloads /var/www/html/templates_c 2>/dev/null || true
chmod -R 775 /var/www/html/attachments /var/www/html/downloads /var/www/html/templates_c 2>/dev/null || true

if [ "$WHMCS_CRON_ENABLED" = "true" ] || [ "$WHMCS_CRON_DAILY_ENABLED" = "true" ]; then
    echo "SHELL=/bin/sh" > /etc/cron.d/whmcs-cron
    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" >> /etc/cron.d/whmcs-cron
    echo "" >> /etc/cron.d/whmcs-cron
    
    if [ "$WHMCS_CRON_ENABLED" = "true" ]; then
        echo "# WHMCS Main Cron" >> /etc/cron.d/whmcs-cron
        echo "${WHMCS_CRON_SCHEDULE} www-data /usr/local/bin/php -q /var/www/html/crons/cron.php >> /var/log/whmcs_cron.log 2>&1" >> /etc/cron.d/whmcs-cron
        echo "" >> /etc/cron.d/whmcs-cron
    fi
    
    if [ "$WHMCS_CRON_DAILY_ENABLED" = "true" ]; then
        echo "# WHMCS Daily Cron" >> /etc/cron.d/whmcs-cron
        echo "${WHMCS_CRON_DAILY_MINUTE} ${WHMCS_CRON_DAILY_HOUR} * * * www-data /usr/local/bin/php -q /var/www/html/crons/cron.php daily >> /var/log/whmcs_cron_daily.log 2>&1" >> /etc/cron.d/whmcs-cron
        echo "" >> /etc/cron.d/whmcs-cron
    fi
    
    chmod 0644 /etc/cron.d/whmcs-cron
    touch /var/log/whmcs_cron.log
    touch /var/log/whmcs_cron_daily.log
    cron
    
    echo "✓ Cron configuré:"
    [ "$WHMCS_CRON_ENABLED" = "true" ] && echo "  - Main: ${WHMCS_CRON_SCHEDULE}"
    [ "$WHMCS_CRON_DAILY_ENABLED" = "true" ] && echo "  - Daily: ${WHMCS_CRON_DAILY_HOUR}:${WHMCS_CRON_DAILY_MINUTE}"
fi

apachectl -k stop >/dev/null 2>&1 || true
rm -f /var/run/apache2/apache2.pid || true

command -v fuser >/dev/null 2>&1 && fuser -k ${APACHE_PORT}/tcp >/dev/null 2>&1 || true

exec "$@"
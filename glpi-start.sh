#!/bin/bash

#Controle du choix de version ou prise de la latest
[[ ! "$VERSION_GLPI" ]] \
        && VERSION_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep tag_name | cut -d '"' -f 4)

if [[ -z "${TIMEZONE}" ]]; then echo "TIMEZONE is unset";
else
	echo "date.timezone = \"$TIMEZONE\"" > /etc/php/7.4/apache2/conf.d/timezone.ini;
	echo "date.timezone = \"$TIMEZONE\"" > /etc/php/7.4/cli/conf.d/timezone.ini;
fi

if [[ -z "$REDIS_HOST" || -z "$REDIS_PORT" || -z "$REDIS_PASS" || -z "$REDIS_DB" ]]; then echo "REDIS isn't used or settings were set incorrect";
else
    REDIS_IS_USED=true
    sed -i 's,session.save_handler = files,session.save_handler = redis,g' /etc/php/7.4/apache2/php.ini;
    echo "session.save_path = \"tcp://${REDIS_HOST}:${REDIS_PORT}?auth=${REDIS_PASS}&database=${REDIS_DB}\"" > /etc/php/7.4/apache2/conf.d/redis_settings.ini;
    sed -i 's,session.save_handler = files,session.save_handler = redis,g' /etc/php/7.4/cli/php.ini;
    echo "session.save_path = \"tcp://${REDIS_HOST}:${REDIS_PORT}?auth=${REDIS_PASS}&database=${REDIS_DB}\"" > /etc/php/7.4/cli/conf.d/redis_settings.ini;
    echo "REDIS settings for PHP session is successfully updated.";
fi

#Enable cookie httponly
sed -i 's,session.cookie_httponly =,session.cookie_httponly = on,g' /etc/php/7.4/apache2/php.ini

SRC_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/tags/${VERSION_GLPI} | jq .assets[0].browser_download_url | tr -d \")
TAR_GLPI=$(basename ${SRC_GLPI})
FOLDER_GLPI=glpi/
FOLDER_WEB=/var/www/html/
FOLDER_TMP=/tmp/

#Download GLPI
wget -nv -P ${FOLDER_TMP} ${SRC_GLPI}
echo "Download source files is successfully done."

#check if TLS_REQCERT is present
if !(grep -q "TLS_REQCERT" /etc/ldap/ldap.conf)
then
    echo "TLS_REQCERT isn't present"
    echo -e "TLS_REQCERT\tnever" >> /etc/ldap/ldap.conf
fi

#Checking for other containers starting
echo "Waiting for other containers starting..."
while [ -f "${FOLDER_WEB}${FOLDER_GLPI}/files/glpi_is_starting" ]; do
    echo '.';
    sleep 1;
done
echo -e "\nGreat, the current container is ready to start!\n";
touch ${FOLDER_WEB}${FOLDER_GLPI}/files/glpi_is_starting

#Untaring source files
tar --skip-old-files -xzf ${FOLDER_TMP}${TAR_GLPI} -C ${FOLDER_WEB}
rm -Rf ${FOLDER_TMP}${TAR_GLPI}
rm -Rf ${FOLDER_WEB}${FOLDER_GLPI}/install/install.php
if [ "${REDIS_IS_USED}" == "true" ]; then
    cd ${FOLDER_WEB}${FOLDER_GLPI} && php bin/console glpi:cache:configure --dsn=redis://${REDIS_PASS}@${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB} --no-interaction
fi

#Checking for GLPI is installed and update\check DB if needed
if [ -f "${FOLDER_WEB}${FOLDER_GLPI}/files/glpi_is_installed" ]; then
    echo "GLPI is already installed."
    cd ${FOLDER_WEB}${FOLDER_GLPI} && php bin/console db:configure --db-host=${DB_HOST} --db-port=${DB_PORT} --db-name=${DB_NAME} --db-user=${DB_USER} --db-password=${DB_PASSWORD} --no-interaction
    cp ${FOLDER_WEB}${FOLDER_GLPI}/files/glpicrypt.key ${FOLDER_WEB}${FOLDER_GLPI}/config/glpicrypt.key
    if [ "$(php bin/console glpi:database:check | grep OK)" ]; then
        echo "DB is already actual."
    else
        php bin/console glpi:maintenance:enable
        php bin/console task:unlock -a
        php bin/console db:update
        if [ "$(php bin/console glpi:database:check | grep OK)" ]; then
            php bin/console glpi:maintenance:disable
            echo "DB is successfully updated."
        else
            php bin/console glpi:maintenance:disable
            rm -rf ${FOLDER_WEB}${FOLDER_GLPI}/files/glpi_is_starting
            echo "DB is corrupted. Please check and fix DB, run it in glpi-webroot directory: php bin/console glpi:database:check"
            exit 1
        fi
    fi
else
    cd ${FOLDER_WEB}${FOLDER_GLPI} && php bin/console db:install --db-host=${DB_HOST} --db-port=${DB_PORT} --db-name=${DB_NAME} --db-user=${DB_USER} --db-password=${DB_PASSWORD} --no-interaction
    touch ${FOLDER_WEB}${FOLDER_GLPI}/files/glpi_is_installed
    cp ${FOLDER_WEB}${FOLDER_GLPI}/config/glpicrypt.key ${FOLDER_WEB}${FOLDER_GLPI}/files/glpicrypt.key
    echo "GLPI is successfully installed."
fi

#Remove lock file
rm -rf ${FOLDER_WEB}${FOLDER_GLPI}/files/glpi_is_starting

#Change owner for all glpi's files
chown -R www-data:www-data ${FOLDER_WEB}${FOLDER_GLPI}

#Modification du vhost par défaut
echo -e "<VirtualHost *:80>\n\tDocumentRoot /var/www/html/glpi\n\n\t<Directory /var/www/html/glpi>\n\t\tAllowOverride All\n\t\tOrder Allow,Deny\n\t\tAllow from all\n\t</Directory>\n\n\tErrorLog /var/log/apache2/error-glpi.log\n\tLogLevel warn\n\tCustomLog /var/log/apache2/access-glpi.log combined\n</VirtualHost>" > /etc/apache2/sites-available/000-default.conf

#Add scheduled task by cron and enable
echo "*/2 * * * * www-data /usr/bin/php /var/www/html/glpi/front/cron.php &>/dev/null" >> /etc/cron.d/glpi
#Start cron service
service cron start

#Activation du module rewrite d'apache
a2enmod rewrite && service apache2 restart && service apache2 stop

#Lancement du service apache au premier plan
/usr/sbin/apache2ctl -D FOREGROUND
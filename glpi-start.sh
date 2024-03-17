#!/bin/bash
LOGS="install_glpi.log"
cat <<EOF > $LOGS

====================================================
## VARIAVEIS

====================================================
EOF
## Setup PHP
 echo "Remove old PHP..."

  yum -y remove \
	php-cli \
	mod_php \
	php-common

  echo "Install ..."

  yum -y install \
	mod_php \
	php-cli \
	php-mysqlnd

  yum -y install \
	php-pear-CAS \
	wget \
	php-json \
	php-mbstring \
	php-mysqli \
	php-session \
	php-gd \
	php-curl \
	php-domxml \
	php-imap \
	php-ldap \
	php-openssl \
	php-opcache \
	php-apcu \
	php-xmlrpc \
	php-intl \
	php-zip \
	php-sodium \
	jq \
	openssl


  # Setup PHP Ini
echo "Setting 99-glpi.ini..."

  cat <<EOF > /etc/php.d/99-glpi.ini
memory_limit = 64M ;
file_uploads = on ;
max_execution_time = 600 ;
register_globals = off ;
magic_quotes_sybase = off ;
session.auto_start = off ;
session.use_trans_sid = 0 ;
EOF

  cat <<EOF > /etc/php.d/99-apcu.ini
apc.enable_cli = 1 ;
EOF



#Controle du choix de version ou prise de la latest
[[ ! "$VERSION_GLPI" ]] \
	&& VERSION_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep tag_name | cut -d '"' -f 4)

if [[ -z "${TIMEZONE}" ]]; then echo "TIMEZONE is unset"; 
else 
echo "date.timezone = \"$TIMEZONE\"" > /etc/php/8.1/apache2/conf.d/timezone.ini;
echo "date.timezone = \"$TIMEZONE\"" > /etc/php/8.1/cli/conf.d/timezone.ini;
fi

#Enable session.cookie_httponly
sed -i 's,session.cookie_httponly = *\(on\|off\|true\|false\|0\|1\)\?,session.cookie_httponly = on,gi' /etc/php/8.1/apache2/php.ini

FOLDER_GLPI=glpi/
FOLDER_WEB=/var/www/html/

#check if TLS_REQCERT is present
if !(grep -q "TLS_REQCERT" /etc/ldap/ldap.conf)
then
	echo "TLS_REQCERT isn't present"
    echo -e "TLS_REQCERT\tnever" >> /etc/ldap/ldap.conf
fi

#Téléchargement et extraction des sources de GLPI
if [ "$(ls ${FOLDER_WEB}${FOLDER_GLPI})" ];
then
	echo "GLPI is already installed"
else
	SRC_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/tags/${VERSION_GLPI} | jq .assets[0].browser_download_url | tr -d \")
	TAR_GLPI=$(basename ${SRC_GLPI})

	wget -P ${FOLDER_WEB} ${SRC_GLPI}
	tar -xzf ${FOLDER_WEB}${TAR_GLPI} -C ${FOLDER_WEB}
	rm -Rf ${FOLDER_WEB}${TAR_GLPI}
	chown -R www-data:www-data ${FOLDER_WEB}${FOLDER_GLPI}
fi

#Adapt the Apache server according to the version of GLPI installed
## Extract local version installed
LOCAL_GLPI_VERSION=$(ls ${FOLDER_WEB}/${FOLDER_GLPI}/version)
## Extract major version number
LOCAL_GLPI_MAJOR_VERSION=$(echo $LOCAL_GLPI_VERSION | cut -d. -f1)
## Remove dots from version string
LOCAL_GLPI_VERSION_NUM=${LOCAL_GLPI_VERSION//./}

## Target value is GLPI 1.0.7
TARGET_GLPI_VERSION="10.0.14"
TARGET_GLPI_VERSION_NUM=${TARGET_GLPI_VERSION//./}
TARGET_GLPI_MAJOR_VERSION=$(echo $TARGET_GLPI_VERSION | cut -d. -f1)

# Compare the numeric value of the version number to the target number
if [[ $LOCAL_GLPI_VERSION_NUM -lt $TARGET_GLPI_VERSION_NUM || $LOCAL_GLPI_MAJOR_VERSION -lt $TARGET_GLPI_MAJOR_VERSION ]]; then
  echo -e "<VirtualHost *:80>\n\tDocumentRoot /var/www/html/glpi\n\n\t<Directory /var/www/html/glpi>\n\t\tAllowOverride All\n\t\tOrder Allow,Deny\n\t\tAllow from all\n\t</Directory>\n\n\tErrorLog /var/log/apache2/error-glpi.log\n\tLogLevel warn\n\tCustomLog /var/log/apache2/access-glpi.log combined\n</VirtualHost>" > /etc/apache2/sites-available/000-default.conf
else
  set +H
  echo -e "<VirtualHost *:80>\n\tDocumentRoot /var/www/html/glpi/public\n\n\t<Directory /var/www/html/glpi/public>\n\t\tRequire all granted\n\t\tRewriteEngine On\n\t\tRewriteCond %{REQUEST_FILENAME} !-f\n\t\n\t\tRewriteRule ^(.*)$ index.php [QSA,L]\n\t</Directory>\n\n\tErrorLog /var/log/apache2/error-glpi.log\n\tLogLevel warn\n\tCustomLog /var/log/apache2/access-glpi.log combined\n</VirtualHost>" > /etc/apache2/sites-available/000-default.conf
fi
chown -R www-data:www-data /var/www/html/glpi/
chmod -R u+rwx /var/www/html/glpi/


/usr/bin/php /var/www/html/glpi/bin/console glpi:database:install \
              --reconfigure \
             	--no-interaction \
             	--force \
             	--db-host=${MARIADB_DB_HOST} \
             	--db-port=${MARIADB_DB_PORT} \
             	--db-name=${MARIADB_DB_NAME} \
             	--db-user=${MARIADB_DB_USER} \
             	--db-password=${MARIADB_DB_PASSWORD}

# Enable time zones
/usr/bin/php /var/www/html/glpi/bin/console migration:timestamps
/usr/bin/php /var/www/html/glpi/bin/console database:enable_timezones
#Add scheduled task by cron and enable
echo "*/2 * * * * www-data /usr/bin/php /var/www/html/glpi/front/cron.php &>/dev/null" > /etc/cron.d/glpi
#Start cron service
service cron start

#Activation du module rewrite d'apache
a2enmod rewrite && service apache2 restart && service apache2 stop

#Fix to really stop apache
pkill -9 apache

#Lancement du service apache au premier plan
/usr/sbin/apache2ctl -D FOREGROUND

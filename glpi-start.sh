#!/bin/bash

#Controle du choix de version ou prise de la latest
[[ ! "$VERSION_GLPI" ]] \
	&& VERSION_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep tag_name | cut -d '"' -f 4)

if [[ -z "${TIMEZONE}" ]]; then echo "TIMEZONE is unset"; 
else echo "date.timezone = \"$TIMEZONE\"" > /etc/php/7.3/apache2/conf.d/timezone.ini;
fi

SRC_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/tags/${VERSION_GLPI} | jq .assets[0].browser_download_url | tr -d \")
TAR_GLPI=$(basename ${SRC_GLPI})
FOLDER_GLPI=glpi/
FOLDER_WEB=/var/www/html/
APACHE=/etc/apache2

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
	wget -P ${FOLDER_WEB} ${SRC_GLPI}
	tar -xzf ${FOLDER_WEB}${TAR_GLPI} -C ${FOLDER_WEB}
	rm -Rf ${FOLDER_WEB}${TAR_GLPI}
	chown -R www-data:www-data ${FOLDER_WEB}${FOLDER_GLPI}
fi

#Activation du vhost HTTP
if [ "$SSL_REDIRECT" != "" ];
then
	sed -e "s#SSL_URL#$SSL_REDIRECT#" -i $APACHE/sites-available/site_redirect.conf
	ln -s $APACHE/sites-available/site_redirect.conf $APACHE/sites-enabled/
else
	ln -s $APACHE/sites-available/site.conf $APACHE/sites-enabled/
fi

#Activation du vhost HTTPS
if [ -e "/etc/certs/glpi.crt" ];
then
	ln -s $APACHE/mods-available/ssl.load $APACHE/mods-enabled/
	ln -s $APACHE/mods-available/ssl.conf $APACHE/mods-enabled/
	ln -s $APACHE/mods-available/socache_shmcb.load $APACHE/mods-enabled/
	ln -s $APACHE/sites-available/site_ssl.conf $APACHE/sites-enabled/
fi

#Add scheduled task by cron and enable
echo "*/2 * * * * www-data /usr/bin/php /var/www/html/glpi/front/cron.php &>/dev/null" >> /etc/cron.d/glpi
#Start cron service
service cron start

#Activation du module rewrite d'apache
a2enmod rewrite && service apache2 restart && service apache2 stop

#Lancement du service apache au premier plan
/usr/sbin/apache2ctl -D FOREGROUND

#On choisit une debian
FROM debian:latest

MAINTAINER DiouxX "github@diouxx.be"

#Ne pas poser de question à l'installation
ENV DEBIAN_FRONTEND noninteractive

#Installation d'apache et de php5 avec extension
RUN apt update \
&& apt -y install \
apache2 \
php5 \
php5-mysql \
php5-ldap \
php5-xmlrpc \
php5-imap \
curl \
php5-curl \
php5-gd \
wget

#Copie et execution du script pour l'installation et l'initialisation de GLPI
COPY glpi-start.sh /opt/
RUN chmod +x /opt/glpi-start.sh
ENTRYPOINT ["/opt/glpi-start.sh"]

#Exposition des ports
EXPOSE 80 443

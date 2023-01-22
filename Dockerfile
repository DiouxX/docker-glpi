#On choisit une debian
FROM debian:11.6

LABEL org.opencontainers.image.authors="github@diouxx.be"


#Ne pas poser de question à l'installation
ENV DEBIAN_FRONTEND noninteractive

#Installation d'apache et de php7.4 avec extension
RUN apt update \
&& apt install --yes --no-install-recommends \
apache2 \
php7.4 \
php7.4-mysql \
php7.4-ldap \
php7.4-xmlrpc \
php7.4-imap \
curl \
php7.4-curl \
php7.4-gd \
php7.4-mbstring \
php7.4-xml \
php7.4-apcu-bc \
php-cas \
php7.4-intl \
php7.4-zip \
php7.4-bz2 \
php7.4-redis \
cron \
wget \
ca-certificates \
jq \
libldap-2.4-2 \
libldap-common \
libsasl2-2 \
libsasl2-modules \
libsasl2-modules-db \
&& rm -rf /var/lib/apt/lists/*

#Copie et execution du script pour l'installation et l'initialisation de GLPI
COPY glpi-start.sh /opt/
RUN chmod +x /opt/glpi-start.sh
ENTRYPOINT ["/opt/glpi-start.sh"]

#Exposition des ports
EXPOSE 80 443

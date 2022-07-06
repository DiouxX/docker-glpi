#On choisit une debian
FROM debian:11.3

LABEL org.opencontainers.image.authors="github@diouxx.be"


#Ne pas poser de question à l'installation
ENV DEBIAN_FRONTEND noninteractive

#Installation dépots php 8.1
RUN apt-get update \ 
&& apt-get -y install apt-transport-https lsb-release ca-certificates curl \
&& curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg \ 
&& sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' \
&& apt-get update

#Installation d'apache et de php 8.1 avec extension
RUN apt install --yes --no-install-recommends \
apache2 \
php8.1 \
php8.1-mysql \
php7.1-ldap \
php8.1-xmlrpc \
php8.1-imap \
php8.1-curl \
php7.1-gd \
php8.1-mbstring \
php8.1-xml \
php8.1-apcu-bc \
php-cas \
php8.1-intl \
php8.1-zip \
php8.1-bz2 \
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

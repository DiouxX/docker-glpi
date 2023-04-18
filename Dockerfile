#On choisit une debian
FROM debian:11.6

LABEL org.opencontainers.image.authors="github@diouxx.be"


#Ne pas poser de question à l'installation / Don't ask questions during installation
ENV DEBIAN_FRONTEND noninteractive

#Install pre-requesites
RUN apt update \
&& apt install --yes --no-install-recommends \
wget \
apt-transport-https \
lsb-release \
ca-certificates

#Add Sury repository for PHP 8.1
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
&& sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'

#Installation d'apache et de php8.1 avec extension / Installation of apache and php8.1 with extensions
RUN apt update \
&& apt upgrade --yes \
&& apt install --yes --no-install-recommends \
apache2 \
php8.1 \
php8.1-mysql \
php8.1-ldap \
php8.1-xmlrpc \
php8.1-imap \
curl \
php8.1-curl \
php8.1-gd \
php8.1-mbstring \
php8.1-xml \
# php8.1-apcu-bc \ - no longer supported https://github.com/krakjoe/apcu-bc/issues/34
php-cas \
php8.1-intl \
php8.1-zip \
php8.1-bz2 \
php8.1-redis \
cron \
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

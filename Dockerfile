# Choose Distribution
FROM debian:12

LABEL org.opencontainers.image.authors="github@local"

# Do not ask questions during installation
ENV DEBIAN_FRONTEND noninteractive

# Installation of apache2 web server as well as PHP 8.2 including extension
RUN apt update \
&& apt install --yes ca-certificates apt-transport-https lsb-release wget curl \
&& apt update \
&& apt install --yes --no-install-recommends \
apache2 \
php8.2 \
php8.2-mysql \
php8.2-ldap \
php8.2-xmlrpc \
php8.2-imap \
php8.2-curl \
php8.2-gd \
php8.2-mbstring \
php8.2-xml \
php-cas \
php8.2-intl \
php8.2-zip \
php8.2-bz2 \
php8.2-redis \
php8.2-xmlreader \
php8.2-xmlwriter \
cron \
jq \
libldap-2.5-0 \
libldap-common \
libsasl2-2 \
libsasl2-modules \
libsasl2-modules-db \
&& rm -rf /var/lib/apt/lists/*

# Copy and Execute Script for Installation and Initialization of GLPI
COPY glpi-start.sh /opt/
RUN chmod +x /opt/glpi-start.sh
ENTRYPOINT ["/opt/glpi-start.sh"]

# Expose Web Server Ports
EXPOSE 80 443

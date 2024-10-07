# Use Debian as the base image
FROM debian:12.5

LABEL org.opencontainers.image.authors="github@diouxx.be"

# Set non-interactive frontend for apt
ENV DEBIAN_FRONTEND noninteractive

# Install Apache and PHP 8.3 with extensions
RUN apt update \
    && apt install --yes ca-certificates apt-transport-https lsb-release wget curl \
    && curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg \
    && sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' \
    && apt update \
    && apt install --yes --no-install-recommends \
        apache2 \
        php8.3 \
        php8.3-mysql \
        php8.3-ldap \
        php8.3-xmlrpc \
        php8.3-imap \
        php8.3-curl \
        php8.3-gd \
        php8.3-mbstring \
        php8.3-xml \
        php-cas \
        php8.3-intl \
        php8.3-zip \
        php8.3-bz2 \
        php8.3-redis \
        cron \
        jq \
        libldap-2.5-0 \
        libldap-common \
        libsasl2-2 \
        libsasl2-modules \
        libsasl2-modules-db \
    && rm -rf /var/lib/apt/lists/*

# Copy and set permissions for the GLPI start script
COPY glpi-start.sh /opt/glpi-start.sh
# RUN chmod +x /opt/glpi-start.sh && chown glpi:glpi /opt/glpi-start.sh
RUN chmod +x /opt/glpi-start.sh

CMD ["/bin/bash", "/opt/glpi-start.sh"]

# Expose ports 80 and 443
EXPOSE 80 443
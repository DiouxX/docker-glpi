# Project to deploy GLPI with docker

![Docker Pulls](https://img.shields.io/docker/pulls/aguyonnet/glpi) ![Docker Stars](https://img.shields.io/docker/stars/aguyonnet/glpi)
# Introduction

Install and run an GLPI instance with docker.

## Deploy a specific release of GLPI
Edit the glpi-install.sh specify a version in the VERSION_GLPI var, then launch a build

# Deploy with docker-compose

## Deploy without persistence data ( for quickly test )
```yaml
version: "3.2"

services:
#mariadb Container
  mariadb:
    image: mariadb:latest
    container_name: mariadb
    hostname: mariadb
    environment:
      - mariadb_ROOT_PASSWORD=password
      - mariadb_DATABASE=glpidb
      - mariadb_USER=glpi_user
      - mariadb_PASSWORD=glpi

#GLPI Container
  glpi:
    image: aguyonnet/glpi
    container_name : glpi
    hostname: glpi
    ports:
      - "80:80"
```

## Deploy with persistence data

To deploy with docker compose, you use *docker-compose.yml* and *mariadb.env* file.
You can modify **_mariadb.env_** to personalize settings like :

* mariadb root password
* GLPI database
* GLPI user database
* GLPI user password


### mariadb.env
```
mariadb_ROOT_PASSWORD=aguyonnet
mariadb_DATABASE=glpidb
mariadb_USER=glpi_user
mariadb_PASSWORD=glpi
```

### docker-compose .yml
```yaml
version: "3.2"

services:
#mariadb Container
  mariadb:
    image: mariadb:latest
    container_name: mariadb-glpi
    hostname: mariadb
    volumes:
      - /var/lib/mysql:/var/lib/mysql
    env_file:
      - ./mariadb.env
    restart: always

#GLPI Container
  glpi:
    image: aguyonnet/glpi
    container_name : glpi
    hostname: glpi
    ports:
      - "80:80"
    volumes:
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
      - /var/www/html/glpi/:/var/www/html/glpi
    environment:
      - TIMEZONE=Europe/Paris
    restart: always
```

To deploy, just run the following command on the same directory as files

```sh
docker-compose up -d
```

# Environnment variables

## TIMEZONE
If you need to set timezone for Apache and PHP

From commande line
```sh
docker run --name glpi -p 80:80 --env "TIMEZONE=Europe/Paris" -d aguyonnet/glpi
```

From docker-compose

Modify this settings
```yaml
environment:
     TIMEZONE=Europe/Paris
```

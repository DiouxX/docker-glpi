# Project to deploy GLPI with docker

[![](https://images.microbadger.com/badges/version/diouxx/glpi.svg)](http://microbadger.com/images/diouxx/glpi "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/diouxx/glpi.svg)](http://microbadger.com/images/diouxx/glpi "Get your own image badge on microbadger.com")

# Table of Contents
1. [Introduction](#introduction)
2. [Deploy CLI](#deploy-with-CLI)
    - [Deploy GLPI without database](#deploy-glpi-without-database)
    - [Deploy GLPI with existing database](#deploy-glpi-with-existing-database)
    - [Deploy GLPI with database and persistance container data](#deploy-glpi-with-database-and-persistance-container-data)
    - [Deploy a specific release of GLPI](#deploy-a-specific-release-of-glpi)
3. [Deploy docker-compose](#deploy-with-docker-compose)
4. [Environnment variables](#environnment-variables)
    - [Timezone](#timezone)

# Introduction

Install and run an GLPI instance with docker.

# Deploy with CLI

## Deploy GLPI without database
```sh
docker run --name glpi -p 80:80 -d diouxx/glpi
```

## Deploy GLPI with existing database
```sh
docker run --name glpi --link yourdatabase:mysql -p 80:80 -d diouxx/glpi
```

## Deploy GLPI with database and persistance container data

For an usage on production environnement or daily usage, it's recommanded to use a data container for persistent data.

* First, create data container

```sh
docker create --name glpi-data --volume /var/www/html/glpi:/var/www/html/glpi busybox /bin/true
```

* Then, you link your data container with GLPI container

```sh
docker run --name glpi --hostname glpi --link mysql:mysql --volumes-from glpi-data -p 80:80 -d diouxx/glpi
```

Enjoy :)

## Deploy a specific release of GLPI
Default, docker run will use the latest release of GLPI.
For an usage on production environnement, it's recommanded to use the latest release.
Here an example for release 9.1.6 :
```sh
docker run --name glpi --hostname glpi --link mysql:mysql --volumes-from glpi-data -p 80:80 --env "VERSION_GLPI=9.1.6" -d diouxx/glpi
```

# Deploy with docker-compose

To deploy with docker compose, you use *docker-compose.yml* and *mysql.env* file.
You can modify **_mysql.env_** to personalize settings like :

* MySQL root password
* GLPI database
* GLPI user database
* GLPI user password

To deploy, just run the following command on the same directory as files

```sh
docker-compose up -d
```

# Environnment variables

## TIMEZONE
If you need to set timezone for Apache and PHP

From commande line
```sh
docker run --name glpi --hostname glpi --link mysql:mysql --volumes-from glpi-data -p 80:80 --env "TIMEZONE=Europe/Brussels" -d diouxx/glpi
```

From docker-compose

Modify this settings
```yml
environment:
     TIMEZONE=Europe/Brussels
```
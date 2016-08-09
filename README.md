# Project to deploy GLPI with docker

Install and run an GLPI instance with docker

## Deploy GLPI without database
```sh
docker run --name glpi -p 80:80 -d diouxx/glpi
```

## Deploy GLPI with existing database
```sh
docker run --name glpi --link yourdatabase:mysql -p 80:80 -d diouxx/glpi
```

## Deploy with docker-compose

To deploy with docker compose, you use <em>docker-compose.yml<em> and <em>mysql.env<em> file.
You can modify <em>**mysql.env**<em> to personalize settings like :

* MySQL root password
* GLPI database
* GLPI user database
* GLPI user password

To deploy, just run the following command on the same directory as files

```sh
docker-compose up -d
```



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

```sh
docker-compose up -d
```



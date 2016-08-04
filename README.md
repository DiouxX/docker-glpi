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

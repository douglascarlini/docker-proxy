#!/bin/bash

domain=$1

# Reset
rm -rf ssl
rm -rf conf.d
git reset --hard && git pull

# Create proxy network
docker network rm proxy_network
docker network create proxy_network

# Stop and delete all containers
docker stop $(docker ps -aq) && docker rm $(docker ps -aq)

# Create and deploy apps containers
docker run --name app1 --network proxy_network -v $PWD/www/app1:/var/www/html -p 20801:80 -d nginx
docker run --name app2 --network proxy_network -v $PWD/www/app2:/var/www/html -p 20802:80 -d nginx
docker run --name app3 --network proxy_network -v $PWD/www/app3:/var/www/html -p 20803:80 -d nginx

# Add permission
chmod +x deploy.sh

# Add apps to proxy
./deploy.sh app1.$domain 20801
./deploy.sh app2.$domain 20802
./deploy.sh app3.$domain 20803

# Listen logs
docker logs -f proxy
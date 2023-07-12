#!/bin/bash

domain=$1

# Reset
rm -rf ssl
rm -rf conf.d

# Reset git and update
git reset --hard && git pull

# Stop and delete all containers
{ docker stop $(docker ps -aq) && docker rm $(docker ps -aq); } || { echo ""; }

# Create and deploy apps containers
docker run --name app1 -v $PWD/www/app1:/usr/share/nginx/html -p 20801:80 -d nginx:latest
docker run --name app2 -v $PWD/www/app2:/usr/share/nginx/html -p 20802:80 -d nginx:latest
docker run --name app3 -v $PWD/www/app3:/usr/share/nginx/html -p 20803:80 -d nginx:latest

# Add permission
bash deploy.sh

#!/bin/bash

email=$1
certs=$PWD/ssl
lines=$(cat sites.txt)
certbot=$PWD/certbot/conf/live
regex="^[a-z][a-z0-9]+(\.[a-z][a-z0-9]+)+\;[0-9]{4,5}$"

if [ -z "$email" ]; then echo "[ERROR] Invalid email"; exit; fi

for line in $lines; do

    if [[ $line =~ $regex ]]; then

        data=($(echo $line | tr ";" " "))
        site=${data[0]}

        docker compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot --email $email -d $site

        cp $certbot/$site/fullchain.pem $certs/$site/
        cp $certbot/$site/privkey.pem $certs/$site/

    fi

done

docker exec proxy nginx -s reload
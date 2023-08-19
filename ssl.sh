#!/bin/bash

email=$1
renew=$2
certs=$PWD/ssl
lines=$(cat sites.txt)
certbot=$PWD/certbot/conf/live
host_regex="^[a-z][a-z0-9]+(\.[a-z][a-z0-9]+)+\;[0-9]{4,5}$"
email_regex='^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$'

if ! [[ $email =~ $email_regex ]]; then
    echo "[ERROR] Invalid email"
    exit
fi

for line in $lines; do

    if [[ $line =~ $host_regex ]]; then

        data=($(echo $line | tr ";" " "))
        site=${data[0]}

        if [ -f "$certbot/$site/fullchain.pem" ] && [ "$2" != "renew" ]; then continue; fi

        docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot --email $email -d $site

        if [ -f "$certbot/$site/fullchain.pem " ]; then cp $certbot/$site/fullchain.pem $certs/$site/; fi
        if [ -f "$certbot/$site/privkey.pem " ]; then cp $certbot/$site/privkey.pem $certs/$site/; fi

    fi

done

docker exec proxy nginx -s reload

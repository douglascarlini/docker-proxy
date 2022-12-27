#!/bin/bash

function error()
{
  printf "\n\t[ERROR] $1\n\n"
  exit
}

line=16
total=0

apps=$(cat apps.txt)
for app in $apps; do

  A=($(echo $app | tr ";" " "))
  domain=${A[0]}; project=${A[1]}; service=${A[2]}; scale=${A[3]}

  site=$domain
  net="${project}_default"
  name="${project}-${service}"

  if ! [ -f docker-compose.yml ]; then { cp templates/docker-compose.yml docker-compose.yml; } || { error "Copy docker compose file fails"; }; fi

  printf "\n[INFO] Site $site\n"

  # Check if site already exists
  if ! [ -f "conf.d/$site.conf" ]; then

    echo "[INFO] Configuring site..."

    # Copy template and configure site
    { cp templates/site.conf conf.d/$site.conf; } || { error "Copy site template file fails"; }
    { sed -i "s/{site}/$site/g" conf.d/$site.conf; } || { error "Configure site template file fails"; }
    { sed -i "s/{name}/$name/g" conf.d/$site.conf; } || { error "Configure site template file fails"; }

    # Configure instances (servers)
    for (( i=1; i<=$scale; i++ )); do
      { sed -i "s/ip_hash\;/ip_hash\;\n\tserver $name-$i\;/g" conf.d/$site.conf; } || { error "Configure app instance $i fails"; }
    done

    # Add app network to proxy service
    if [ -z "$(cat docker-compose.yml | grep $net)" ]; then
      { sed -i "${line}s/^/      \- $net\n/g" docker-compose.yml; } || { error "Add site network to proxy fails"; }
      { printf "  $net:\n      name: $net\n" >> docker-compose.yml; } || { error "Add external network fails"; }
    fi

    # Generate auto-signed SSL certified
    if ! [ -d ssl/$site ]; then

      { mkdir -p ssl/$site; } || { exit; }

      echo "[INFO] Generating auto-signed SSL certified..."

      { openssl genrsa -out ssl/$site/server.key 2048 &>/dev/null; } || { error "Create SSL key fails"; }
      { openssl req -new -key ssl/$site/server.key -sha256 -out ssl/$site/server.csr -subj "/CN=${site}" &>/dev/null; } || { error "Create SSL csr fails"; }
      { openssl x509 -req -days 365 -in ssl/$site/server.csr -signkey ssl/$site/server.key -sha256 -out ssl/$site/server.crt &>/dev/null; } || { error "Create SSL crt fails"; }

    fi

    # Create network if not exists
    if [ -z "$(docker network ls | grep $net)" ]; then
      echo "[INFO] Creating private network for $net..."
      { docker network create $net &>/dev/null; } || { error "Create network fails"; }
    fi

    # Add site to /etc/hosts
    if [ -z "$(cat /etc/hosts | grep $site)" ]; then
      echo "[INFO] Trying to add site entries to /etc/hosts file..."
      { echo "127.0.0.1 $site" >> /etc/hosts &>/dev/null; } || { echo "[WARN] You must add $site to /etc/hosts file manually."; }
      { echo "127.0.0.1 www.$site" >> /etc/hosts &>/dev/null; } || { echo "[WARN] You must add www.$site to /etc/hosts file manually."; }
    fi

    # Sites configured
    total=$((total+1))

  else

    echo "[WARN] Site already configured"

  fi

done

if [ $total -gt 0 ]; then

  # Down proxy service
  { docker-compose down &>/dev/null; }

  # Build and UP proxy service
  printf "\n[INFO] Running proxy service...\n"
  { docker-compose up --build -d &>/dev/null; } || { error "Start fails"; }

  printf "[INFO] Service deploy time: $(($SECONDS / 60))m$(($SECONDS % 60))s\n\n"

else

  printf "\n[WARN] No changes\n\n"

fi
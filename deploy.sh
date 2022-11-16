#!/bin/bash

function error()
{
  printf "\n\t[ERROR] $1\n\n"
  exit
}

if [ "$#" != "3" ]; then error "You must provide 3 arguments [site container network]"; fi

net=$3
site=$1
name=$2
line=22
total=0
ip="127.0.0.1"

if ! [ -f docker-compose.yml ]; then { cp templates/docker-compose.yml docker-compose.yml; } || { error "Copy docker compose file fails"; }; fi

printf "\n[INFO] Site $site\n"

# Check if site already exists
if ! [ -f "conf.d/$site.conf" ]; then

  echo "[INFO] Configuring site..."

  # Copy template and configure site
  { cp templates/site.conf conf.d/$site.conf; } || { error "Copy site template file fails"; }
  { sed -i '' "s/{site}/$site/g" conf.d/$site.conf; } || { error "Configure site template file fails"; }
  { sed -i '' "s/{name}/$name/g" conf.d/$site.conf; } || { error "Configure site template file fails"; }

  # Add app network to proxy service
  if [ -z "$(cat docker-compose.yml | grep $net)" ]; then
    { sed -i '' "${line}s/^/      \- $net\n/g" docker-compose.yml; } || { error "Add site network to proxy fails"; }
    { printf "  $net:\n    external:\n      name: $net\n" >> docker-compose.yml; } || { error "Add external network fails"; }
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
    { echo "$ip $site" >> /etc/hosts &>/dev/null; } || { echo "[WARN] You must add $site to /etc/hosts file manually."; }
    { echo "$ip www.$site" >> /etc/hosts &>/dev/null; } || { echo "[WARN] You must add www.$site to /etc/hosts file manually."; }
  fi

  # Sites configured
  total=$((total+1))

else

  echo "[WARN] Site already configured"

fi

if [ $total -gt 0 ]; then

  # Build and UP proxy service

  printf "[INFO] Running proxy service...\n"
  { docker-compose up -d &>/dev/null; } || { error "Start fails"; }

  printf "\n[INFO] Service deploy time: $(($SECONDS / 60))m$(($SECONDS % 60))s\n\n"

else

  printf "\n[WARN] No changes\n\n"

fi

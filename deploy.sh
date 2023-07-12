#!/bin/bash

function error() {
  printf "\n\t[ERROR] $1\n\n"
  exit
}

site=$1
port=$2

net="proxy_network"

printf "\n[INFO] Site $site\n"

# Check if site already exists
if ! [ -f "conf.d/$site.conf" ]; then

  echo "[INFO] Configuring site..."

  # Copy template and configure site
  { cp templates/site.conf conf.d/$site.conf; } || { error "Copy site template file fails"; }
  { sed -i "s/{site}/$site/g" conf.d/$site.conf; } || { error "Configure site template file fails"; }
  { sed -i "s/ip_hash\;/ip_hash\;\n\tserver localhost:$port\;/g" conf.d/$site.conf; } || { error "Configure nginx stream fails"; }

  # Generate auto-signed SSL certified
  if ! [ -d ssl/$site ]; then

    { mkdir -p ssl/$site; } || { exit; }

    echo "[INFO] Generating auto-signed SSL certified..."

    { openssl genrsa -out ssl/$site/server.key 2048 &>/dev/null; } || { error "Create SSL key fails"; }
    { openssl req -new -key ssl/$site/server.key -sha256 -out ssl/$site/server.csr -subj "/CN=${site}" &>/dev/null; } || { error "Create SSL csr fails"; }
    { openssl x509 -req -days 365 -in ssl/$site/server.csr -signkey ssl/$site/server.key -sha256 -out ssl/$site/server.crt &>/dev/null; } || { error "Create SSL crt fails"; }

  fi

  # Add site to /etc/hosts
  if [ -z "$(cat /etc/hosts | grep $site)" ]; then
    echo "[INFO] Trying to add site entries to /etc/hosts file..."
    { echo "127.0.0.1 $site" >>/etc/hosts &>/dev/null; } || { echo "[WARN] You must add $site to /etc/hosts file manually."; }
    { echo "127.0.0.1 www.$site" >>/etc/hosts &>/dev/null; } || { echo "[WARN] You must add www.$site to /etc/hosts file manually."; }
  fi

  # Create network if not exists
  if [ -z "$(docker network ls | grep $net)" ]; then
    echo "[INFO] Creating private proxy network named $net..."
    { docker network create $net &>/dev/null; } || { error "Create network fails"; }
  fi

else

  echo "[WARN] Site already configured"

fi

# Down proxy service
{ docker-compose down &>/dev/null; }

# Build and UP proxy service
printf "\n[INFO] Running proxy service...\n"
{ docker-compose up --build -d &>/dev/null; } || { error "Start fails"; }

printf "[INFO] Service deploy time: $(($SECONDS / 60))m$(($SECONDS % 60))s\n\n"

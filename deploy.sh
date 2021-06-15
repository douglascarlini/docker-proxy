#!/bin/bash

function error()
{
  printf "\n\t[ERROR] $1\n\n"
  exit
}

line=10
total=0
ip=$(ifconfig | grep -A 1 eth0 | tail -1 | awk '{print $2}')

if ! [ -f default.conf ]; then { cp templates/default.conf default.conf; } || { error "Copy NGINX default config fails"; }; fi
if ! [ -f not-found.html ]; then { cp templates/not-found.html not-found.html; } || { error "Copy not-found template fails"; }; fi
if ! [ -f docker-compose.yml ]; then { cp templates/docker-compose.yml docker-compose.yml; } || { error "Copy docker-compose file fails"; }; fi

for host in "$@"; do

  printf "\n[INFO] Site $host\n"

  # Check if host already exists
  if [ -z "$(cat default.conf | grep $host)" ] && [ -z "$(cat docker-compose.yml | grep $host)" ]; then
    
    echo "[INFO] Configuring site..."

    # Copy template and configure site
    { cp templates/site.conf site.conf; } || { error "Copy site template file fails"; }
    { sed -i "s/{host}/$host/g" site.conf; } || { error "Configure site template file fails"; }

    # Add site to default configuration
    { cat site.conf | cat - default.conf > temp && mv temp default.conf; } || { error "Add site to NGINX fails"; }

    # Add app network to proxy service
    { sed -i "${line}s/^/      \- $host\n/g" docker-compose.yml; } || { error "Add site network to proxy fails"; }
    { printf "  $host:\n    external:\n      name: $host\n" >> docker-compose.yml; } || { error "Add external network fails"; }

    # Generate auto-signed SSL certified
    if ! [ -d ssl/$host ]; then
    
      { mkdir -p ssl/$host; } || { exit; }

      echo "[INFO] Generating auto-signed SSL certified..."

      { openssl genrsa -out ssl/$host/server.key 2048 &> /dev/null; } || { error "Create SSL key fails"; }
      { openssl req -new -key ssl/$host/server.key -sha256 -out ssl/$host/server.csr -subj "/CN=${host}" &> /dev/null; } || { error "Create SSL csr fails"; }
      { openssl x509 -req -days 365 -in ssl/$host/server.csr -signkey ssl/$host/server.key -sha256 -out ssl/$host/server.crt &> /dev/null; } || { error "Create SSL crt fails"; }
      
    fi

    # Create network if not exists
    if [ -z "$(docker network ls | grep $host)" ]; then
      echo "[INFO] Creating private network for $host..."
      { docker network create $host >> $log &> /dev/null; } || { error "Create network fails"; }
    fi

    # Add site to /etc/hosts
    if [ -z "$(cat /etc/hosts | grep $host)" ]; then
      echo "[INFO] Trying to add site entry to /etc/hosts file..."
      { echo "$ip $host" >> /etc/hosts &> /dev/null; } || { echo "[WARN] You must add site to /etc/hosts file manually."; }
    fi
    
    # Sites configured
    total=$((total+1))
    
  else
    
    echo "[WARN] Site already configured"
    
  fi
  
done

if [ $total -gt 0 ]; then

  # Build and UP proxy service

  printf "\n[INFO] Building proxy image...\n"
  { docker-compose build &> /dev/null; } || { error "Build fails"; }

  printf "[INFO] Running proxy service...\n"
  { docker-compose up -d &> /dev/null; } || { error "Start fails"; }

  printf "\n[INFO] Service deploy time: $(($SECONDS / 60))m$(($SECONDS % 60))s\n\n"
  
else

  printf "\n[WARN] No changes\n\n"
  
fi

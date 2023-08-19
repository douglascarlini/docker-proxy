#!/bin/bash

function fail() {
  printf "[FAIL] $1\n"
  exit
}

function warn() {
  printf "[WARN] $1\n"
}

function info() {
  printf "[INFO] $1\n"
}

if [[ "$(uname)" != "Linux" ]]; then fail "Run only on Linux"; fi
if ! [ -f "sites.txt" ]; then fail "Sites file not found"; fi
if [ -z "$(cat sites.txt)" ]; then fail "Sites empty"; fi

total=0
index=0

certs=$PWD/ssl
file="deploy.log"
lines=$(cat sites.txt)
host=$(hostname -I | awk '{print $1}')
regex="^[a-z][a-z0-9]+(\.[a-z][a-z0-9]+)+\;[0-9]{4,5}$"

info "Running proxy container..."
{ docker-compose up -d &>$file; } || { fail "Proxy start fails"; }

for line in $lines; do

  ((index++))

  if [[ $line =~ $regex ]]; then

    data=($(echo $line | tr ";" " "))

    site=${data[0]}
    port=${data[1]}

    # Check if site already exists
    if ! [ -f "conf.d/$site.conf" ]; then

      info "Site $site on port $port..."

      # Copy template and configure site
      { cp templates/site.conf conf.d/$site.conf; } || { fail "Copy site template file fails"; }
      { sed -i "s/{site}/$site/g" conf.d/$site.conf; } || { fail "Configure site template file fails"; }
      { sed -i "s/ip_hash\;/ip_hash\;\n\tserver $host:$port\;/g" conf.d/$site.conf; } || { fail "Configure nginx stream fails"; }

      # Generate auto-signed SSL certified
      if ! [ -d ssl/$site ]; then

        { mkdir -p ssl/$site; } || { exit; }

        info "Generating auto-signed SSL certified..."

        { openssl genrsa -out $certs/$site/server.key 2048 &>$file; } || { fail "Create SSL key fails"; }
        { openssl req -new -key $certs/$site/server.key -sha256 -out $certs/$site/server.csr -subj "/CN=$site" &>$file; } || { fail "Create SSL csr fails"; }
        { openssl x509 -req -days 365 -in $certs/$site/server.csr -signkey $certs/$site/server.key -sha256 -out $certs/$site/fullchain.pem &>$file; } || { fail "Create SSL fullchain fails"; }
        { openssl rsa -in $certs/$site/server.key -out $certs/$site/privkey.pem &>$file; } || { fail "Create SSL privkey fails"; }

      fi

      # Sites configured
      total=$((total + 1))

    fi

  fi

done

if [ $total -gt 0 ]; then

  # Build and UP proxy service
  info "Reloading proxy service..."
  { docker exec proxy nginx -s reload; } || { fail "Reload failed"; }
  info "Proxy service deploy time: $(($SECONDS / 60))m$(($SECONDS % 60))s"

fi

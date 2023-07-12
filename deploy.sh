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

if ! [ -f "sites.txt" ]; then fail "Sites file not found"; fi

total=0
net="proxy_network"
lines=$(cat sites.txt)

for line in $lines; do

  info $line

  data=($(echo $line | tr ";" " "))

  site=${data[0]}
  port=${data[1]}

  # Check if site already exists
  if ! [ -f "conf.d/$site.conf" ]; then

    info "Site $site on port $port..."

    # Copy template and configure site
    { cp templates/site.conf conf.d/$site.conf; } || { fail "Copy site template file fails"; }
    { sed -i "s/{site}/$site/g" conf.d/$site.conf; } || { fail "Configure site template file fails"; }
    { sed -i "s/ip_hash\;/ip_hash\;\n\tserver localhost:$port\;/g" conf.d/$site.conf; } || { fail "Configure nginx stream fails"; }

    # Generate auto-signed SSL certified
    if ! [ -d ssl/$site ]; then

      { mkdir -p ssl/$site; } || { exit; }

      info "Generating auto-signed SSL certified..."

      { openssl genrsa -out ssl/$site/server.key 2048 &>/dev/null; } || { fail "Create SSL key fails"; }
      { openssl req -new -key ssl/$site/server.key -sha256 -out ssl/$site/server.csr -subj "/CN=${site}" &>/dev/null; } || { fail "Create SSL csr fails"; }
      { openssl x509 -req -days 365 -in ssl/$site/server.csr -signkey ssl/$site/server.key -sha256 -out ssl/$site/server.crt &>/dev/null; } || { fail "Create SSL crt fails"; }

    fi

    # Sites configured
    total=$((total + 1))

  fi

done

if [ $total -gt 0 ]; then

  # Down proxy service
  { docker-compose down &>/dev/null; }

  # Build and UP proxy service
  info "Running proxy service..."
  { docker-compose up --build -d &>/dev/null; } || { fail "Start fails"; }

  info "Service deploy time: $(($SECONDS / 60))m$(($SECONDS % 60))s"

fi

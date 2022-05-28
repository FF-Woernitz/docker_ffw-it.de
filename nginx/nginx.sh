#!/bin/sh

set -e

if [ ! -f /etc/nginx/sites/ssl/ssl-dhparams.pem ]; then
  mkdir -p "/etc/nginx/sites/ssl"
  openssl dhparam -out /etc/nginx/sites/ssl/ssl-dhparams.pem 2048
fi

if [ ! -f "/etc/nginx/sites/ssl/dummy/fullchain.pem" ]; then
  echo "Generating dummy ceritificate"
  mkdir -p "/etc/nginx/sites/ssl/dummy"
  printf "[dn]\nCN=DUMMY\nO=TobsA.WTF\n[req]\ndistinguished_name = dn\n[EXT]\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth" > openssl.cnf
  openssl req -x509 -out "/etc/nginx/sites/ssl/dummy/fullchain.pem" -keyout "/etc/nginx/sites/ssl/dummy/privkey.pem" \
    -newkey rsa:2048 -nodes -sha256 -days 3650 \
    -subj "/CN=DUMMY" -extensions EXT -config openssl.cnf
  rm -f openssl.cnf
fi

exec nginx -g "daemon off;"

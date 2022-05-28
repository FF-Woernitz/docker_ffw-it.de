#!/bin/sh

cd /workdir
echo "Renewing Let's Encrypt Certificates... (`date`)"
certbot renew --no-random-sleep-on-renew --deploy-hook "/bin/touch /tmp/CERTBOT_RELOAD"

if [ -f "/tmp/CERTBOT_RELOAD" ]; then
  /opt/reload_services.sh
  rm /tmp/CERTBOT_RELOAD
fi
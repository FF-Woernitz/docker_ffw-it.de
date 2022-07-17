#!/bin/ash
set -e

echo "Copy ssl to /ssl"
if [ -d /ssl ]; then
  rm -rf /ssl
fi
mkdir /ssl
cp /etc/letsencrypt/live/npm-1/* /ssl/
chown -R mosquitto:mosquitto /ssl

/docker-entrypoint.sh "$@"
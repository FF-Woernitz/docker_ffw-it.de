#!/usr/bin/env bash

cd /workdir

echo "Reloading Nginx configuration"
docker-compose exec -T nginx nginx -s reload
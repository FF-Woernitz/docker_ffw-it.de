#!/usr/bin/env bash

cd /workdir

echo "Reloading MQTT"
docker kill --signal=HUP mqtt
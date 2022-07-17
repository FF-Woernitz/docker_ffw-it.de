#!/bin/bash

while true; do
  echo "Monitoring letsencrypt for cert changes..."
  inotifywait -e modify -e create -e delete -e move -r /etc/letsencrypt/live;
  echo "Detected changes, wait 30 seconds before reload."
  sleep 30;
  echo "Reloading services."
  /opt/reload_services.sh;
done
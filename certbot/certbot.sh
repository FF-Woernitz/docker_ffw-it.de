#!/bin/bash

set -e

trap exit INT TERM

if [ -z "$DOMAINS" ]; then
  echo "DOMAINS environment variable is not set"
  exit 1;
fi

until nc -z nginx 80; do
  echo "Waiting for nginx to start..."
  sleep 10s & wait ${!}
done

if [ "$CERTBOT_TEST_CERT" != "0" ]; then
  test_cert_arg="--test-cert"
fi

domain_list=($DOMAINS)
emails_list=($CERTBOT_EMAILS)
for i in "${!domain_list[@]}"; do
  domain="${domain_list[i]}"

  mkdir -p "/var/www/certbot/$domain"

  if [ -d "/etc/letsencrypt/live/$domain" ]; then
    echo "Let's Encrypt certificate for $domain already exists"
    continue
  fi

  echo "Obtaining the certificate for $domain"

  if [ -z "${emails_list[i]}" ]; then
    email_arg="--register-unsafely-without-email"
  else
    email_arg="--email ${emails_list[i]}"
  fi

  certbot certonly \
    --webroot \
    -w "/var/www/certbot" \
    -d "$domain" -d "www.$domain" \
    $test_cert_arg \
    $email_arg \
    --rsa-key-size "${CERTBOT_RSA_KEY_SIZE:-4096}" \
    --agree-tos \
    --noninteractive \
    --deploy-hook "/bin/touch /tmp/CERTBOT_RELOAD" --force-renewal || true
done

if [ -f "/tmp/CERTBOT_RELOAD" ]; then
  /opt/reload_services.sh
  rm /tmp/CERTBOT_RELOAD
fi

/etc/periodic/daily/renew_certs

/usr/sbin/crond -f -l 4

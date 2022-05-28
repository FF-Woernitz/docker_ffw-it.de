FROM certbot/certbot:latest

RUN apk update && \
    apk add --no-cache bash docker-cli docker-compose

COPY certbot.sh /opt/
RUN chmod +x /opt/certbot.sh

COPY renew_certs.sh /etc/periodic/daily/renew_certs
RUN chmod +x /etc/periodic/daily/renew_certs

COPY reload_services.sh /opt/reload_services.sh
RUN chmod +x /opt/reload_services.sh

ENTRYPOINT ["/opt/certbot.sh"]
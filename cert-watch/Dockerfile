FROM alpine:latest

RUN apk add --no-cache bash docker-cli docker-compose inotify-tools

COPY cert-watch.sh /opt/
RUN chmod +x /opt/cert-watch.sh

COPY reload_services.sh /opt/reload_services.sh
RUN chmod +x /opt/reload_services.sh

ENTRYPOINT ["/opt/cert-watch.sh"]
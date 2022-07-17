FROM jc21/nginx-proxy-manager:latest

RUN addgroup --gid 1883 mosquitto && \
    adduser --uid 1883 --disabled-password --no-create-home --disabled-login --home /nonexistent --shell /sbin/nologin --ingroup mosquitto --gecos "" mosquitto

COPY custom-init.sh /custom-init.sh
RUN chmod +x /custom-init.sh

COPY mosquitto-permissions.sh /mosquitto-permissions.sh
RUN chmod +x /mosquitto-permissions.sh

ENTRYPOINT ["/custom-init.sh"]
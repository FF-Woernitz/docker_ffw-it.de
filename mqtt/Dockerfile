FROM eclipse-mosquitto

COPY custom-init.sh /custom-init.sh
RUN chmod +x /custom-init.sh

ENTRYPOINT ["/custom-init.sh"]
CMD ["/usr/sbin/mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
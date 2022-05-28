FROM nginx:alpine

RUN apk add --no-cache openssl

COPY nginx.sh /customization/

RUN chmod +x /customization/nginx.sh

EXPOSE 80

CMD ["/customization/nginx.sh"]
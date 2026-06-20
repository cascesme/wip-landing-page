FROM nginx:alpine
RUN apk add --no-cache bash
COPY nginx.conf /etc/nginx/nginx.conf
COPY html/index.html.template /tmp/index.html.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]

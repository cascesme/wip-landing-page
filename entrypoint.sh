#!/bin/bash
set -e

export WIP_TITLE="${WIP_TITLE:-Work in Progress}"
export WIP_SUBTITLE="${WIP_SUBTITLE:-This website will be available soon.}"

envsubst '$WIP_TITLE $WIP_SUBTITLE' \
  < /tmp/index.html.template \
  > /usr/share/nginx/html/index.html

exec nginx -g "daemon off;"

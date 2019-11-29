#!/bin/bash

PWD=$(pwd)
DIRNAME=$(dirname $0)

SITE_URL_FROM_PARAMS=$1

if [ ! -w "/etc/nginx/sites-available/" ]; then
  echo "/!\ cannot write on /etc/nginx/sites-available/ directory."
  echo "did you try with sudo ?"
  exit;
fi

SITE_URL_FROM_PARAMS=${SITE_URL_FROM_PARAMS:-wordpress.local}
read -p "Enter the local site url [$SITE_URL_FROM_PARAMS]: " SITE_URL
SITE_URL=${SITE_URL:-$SITE_URL_FROM_PARAMS}

echo "SITE_URL : $SITE_URL"

echo "A) remove nginx.conf for website"

if [ -f "/etc/nginx/sites-available/$SITE_URL.conf" ]; then
  echo "- Remove conf"
  rm -f /etc/nginx/sites-available/$SITE_URL.conf
fi

if [ -f "/etc/nginx/sites-enabled/$SITE_URL.conf" ]; then
  echo "- Remove symlink"
  rm -f /etc/nginx/sites-enabled/$SITE_URL.conf
fi

echo "B) uninstall site in /etc/hosts"

echo "remove lines"
sed -i "/$SITE_URL/d" /etc/hosts

echo "C) test conf and restart nginx"

nginx -t; service nginx restart; echo "all done 😃";

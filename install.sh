#!/bin/bash

PWD=$(pwd)
DIRNAME=$(dirname $0)

SITE_URL_FROM_PARAMS=$1
WEB_ROOT_PATH_FROM_PARAMS=$2
CMS_NAME_FROM_PARAMS=$3
EXTRA_CONF=$4
NGINX_LOG_PATH=$5
PHPFPM_SOCK=$6

if [ ! -w "/etc/nginx/sites-available/" ]; then
  echo "/!\ cannot write on /etc/nginx/sites-available/ directory."
  echo "did you try with sudo ?"
  exit;
fi

SITE_URL_FROM_PARAMS=${SITE_URL_FROM_PARAMS:-wordpress.local}
read -p "Enter the local site url [$SITE_URL_FROM_PARAMS]: " SITE_URL
SITE_URL=${SITE_URL:-$SITE_URL_FROM_PARAMS}

echo "SITE_URL : $SITE_URL"

WEB_ROOT_PATH_FROM_PARAMS=${WEB_ROOT_PATH_FROM_PARAMS:-/var/www/site}
read -p "Enter the web root path [$WEB_ROOT_PATH_FROM_PARAMS]: " WEB_ROOT_PATH
WEB_ROOT_PATH=${WEB_ROOT_PATH:-$WEB_ROOT_PATH_FROM_PARAMS}

echo "WEB_ROOT_PATH : $WEB_ROOT_PATH"

CMS_NAME_FROM_PARAMS=${CMS_NAME_FROM_PARAMS:-wordpress}
read -p "Enter the name of the cms (wordpress,magento,symfony) [$CMS_NAME_FROM_PARAMS]: " CMS_NAME
CMS_NAME=${CMS_NAME:-$CMS_NAME_FROM_PARAMS}

echo "CMS_NAME : $CMS_NAME"

NGINX_LOG_PATH=${NGINX_LOG_PATH:-/var/log/nginx/}
read -p "Enter the path for nginx error and access log [$NGINX_LOG_PATH]: " NGINX_LOG_PATH
NGINX_LOG_PATH=${NGINX_LOG_PATH:-/var/log/nginx/}

PHPFPM_SOCK=${PHPFPM_SOCK:-/var/run/php/php7.2-fpm.sock}
read -p "Enter the php-fpm socket to use [$PHPFPM_SOCK]: " PHPFPM_SOCK
PHPFPM_SOCK=${PHPFPM_SOCK:-/var/run/php/php7.2-fpm.sock}

echo "A) Create nginx.conf for website"

if [ -f "/etc/nginx/sites-available/$SITE_URL.conf" ]; then
  echo "- Remove old conf"
  rm -f /etc/nginx/sites-available/$SITE_URL.conf
fi

echo "- Copy fresh file"
cp  $DIRNAME/$CMS_NAME.conf /etc/nginx/sites-available/$SITE_URL.conf

echo "- Replace placeholder by local values"
sed -i 's,--WEB_ROOT_PATH--,'"$WEB_ROOT_PATH"',' /etc/nginx/sites-available/$SITE_URL.conf
sed -i 's,--PHPFPM_SOCK--,'"$PHPFPM_SOCK"',' /etc/nginx/sites-available/$SITE_URL.conf
sed -i 's,--NGINX_LOG_PATH--,'"$NGINX_LOG_PATH"',' /etc/nginx/sites-available/$SITE_URL.conf
sed -i 's,--SITE_URL--,'"$SITE_URL"',' /etc/nginx/sites-available/$SITE_URL.conf
if [ $EXTRA_CONF -a -f $EXTRA_CONF ]; then
  sed -i 's,--EXTRA--,'"include snippets/$SITE_URL.extra.conf;"',' /etc/nginx/sites-available/$SITE_URL.conf
else
  sed -i 's,--EXTRA--,'',' /etc/nginx/sites-available/$SITE_URL.conf

fi

if [ -f "/etc/nginx/sites-enabled/$SITE_URL.conf" ]; then
  echo "- Remove old symlink"
  rm -f /etc/nginx/sites-enabled/$SITE_URL.conf
fi

echo "- Create symlink"
ln -s /etc/nginx/sites-available/$SITE_URL.conf /etc/nginx/sites-enabled/


if [ $EXTRA_CONF - a -f $EXTRA_CONF ]; then
  echo "- Copy EXTRA_CONF"
  cp $EXTRA_CONF /etc/nginx/snippets/$SITE_URL.extra.conf
fi

echo "B) install site in /etc/hosts"

echo "remove old lines"
sed -i "/$SITE_URL/d" /etc/hosts
echo "add new ones"
echo "127.0.0.1  $SITE_URL" >> /etc/hosts

echo "C) test conf and restart nginx"

nginx -t; service nginx restart; echo "all done 😃";
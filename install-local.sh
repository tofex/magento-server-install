#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -w  Web path
  -v  Magento version
  -o  Database host, default: localhost
  -p  Database port, default: 3306
  -u  Name of the database user
  -s  Password of the database user
  -b  Name of the database
  -m  Main host name
  -c  Crypt key
  -f  Share script file name
  -a  shared file path, default: shared

Example: ${scriptName} -w /var/www/magento/htdocs -v 2.3.7 -u magento -s magento -b magento -m dev.magento2.de -c 12345 -f /tmp/ops-create-shared-local.sh -a shared
EOF
}

trim()
{
  echo -n "$1" | xargs
}

webPath=
magentoVersion=
databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=
mainHostName=
cryptKey=
shareScript=
sharedPath=

while getopts hw:v:o:p:u:s:b:m:c:f:a:? option; do
  case "${option}" in
    h) usage; exit 1;;
    w) webPath=$(trim "$OPTARG");;
    v) magentoVersion=$(trim "$OPTARG");;
    o) databaseHost=$(trim "$OPTARG");;
    p) databasePort=$(trim "$OPTARG");;
    u) databaseUser=$(trim "$OPTARG");;
    s) databasePassword=$(trim "$OPTARG");;
    b) databaseName=$(trim "$OPTARG");;
    m) mainHostName=$(trim "$OPTARG");;
    c) cryptKey=$(trim "$OPTARG");;
    f) shareScript=$(trim "$OPTARG");;
    a) sharedPath=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${webPath}" ]]; then
  echo "No web path to download specified!"
  exit 1
fi

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version to download specified!"
  exit 1
fi

if [[ -z "${databaseHost}" ]]; then
  databaseHost="localhost"
fi

if [[ -z "${databasePort}" ]]; then
  databasePort="3306"
fi

if [[ -z "${databaseUser}" ]]; then
  echo "No database user specified!"
  usage
  exit 1
fi

if [[ -z "${databasePassword}" ]]; then
  echo "No database password specified!"
  usage
  exit 1
fi

if [[ -z "${databaseName}" ]]; then
  echo "No database name specified!"
  usage
  exit 1
fi

if [[ -z "${mainHostName}" ]]; then
  echo "No main host name specified!"
  usage
  exit 1
fi

if [[ -z "${cryptKey}" ]]; then
  echo "No crypt key specified!"
  usage
  exit 1
fi

if [[ -z "${shareScript}" ]]; then
  echo "No share script to install demo data specified!"
  exit 1
fi

if [[ -z "${sharedPath}" ]]; then
  sharedPath="static"
fi

webRoot=$(dirname "${webPath}")

cd "${webPath}"

if [[ ${magentoVersion:0:1} == 1 ]]; then
  rm -rf app/etc/local.xml
  php -f install.php -- --license_agreement_accepted yes \
    --locale de_DE --timezone "Europe/Berlin" --default_currency EUR \
    --db_host "${databaseHost}:${databasePort}" --db_name "${databaseName}" --db_user "${databaseUser}" --db_pass "${databasePassword}" \
    --url "https://${mainHostName}/" --skip_url_validation --use_rewrites yes \
    --use_secure yes --secure_base_url "https://${mainHostName}/" --use_secure_admin yes \
    --admin_lastname Owner --admin_firstname Store --admin_email "admin@tofex.com" \
    --admin_username admin --admin_password adminadminadmin123 \
    --encryption_key "${cryptKey}"

  "${shareScript}" \
    -w "${webPath}" \
    -s "${webRoot}/${sharedPath}" \
    -f app/etc/local.xml \
    -o
else
  rm -rf app/etc/env.php
  bin/magento setup:install "--base-url=https://${mainHostName}/" "--base-url-secure=https://${mainHostName}/" \
    "--db-host=${databaseHost}:${databasePort}" "--db-name=${databaseName}" "--db-user=${databaseUser}" "--db-password=${databasePassword}" \
    --use-secure-admin=1 --backend-frontname=admin \
    --admin-lastname=Owner --admin-firstname=Store --admin-email=admin@tofex.de \
    --admin-user=admin --admin-password=adminadminadmin123 \
    --language=de_DE --currency=EUR --timezone=Europe/Berlin \
    --key "${cryptKey}" \
    --session-save=files --use-rewrites=1

  "${shareScript}" \
    -w "${webPath}" \
    -s "${webRoot}/${sharedPath}" \
    -f app/etc/env.php \
    -o
  "${shareScript}" \
    -w "${webPath}" \
    -s "${webRoot}/${sharedPath}" \
    -f app/etc/config.php \
    -o
fi

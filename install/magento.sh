#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  -h  Show this message

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

magentoVersion=
cryptKey=
databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=
webPath=
mainHostName=
shareScript=
sharedPath=

while getopts hm:e:d:r:c:o:p:u:s:b:t:v:w:k:g:l:i:j:z:x:y:n:f:a:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) ;;
    d) ;;
    r) ;;
    c) cryptKey=$(trim "$OPTARG");;
    o) databaseHost=$(trim "$OPTARG");;
    p) databasePort=$(trim "$OPTARG");;
    u) databaseUser=$(trim "$OPTARG");;
    s) databasePassword=$(trim "$OPTARG");;
    b) databaseName=$(trim "$OPTARG");;
    t) ;;
    v) ;;
    w) webPath=$(trim "$OPTARG");;
    k) ;;
    g) ;;
    l) ;;
    i) ;;
    j) ;;
    z) ;;
    x) ;;
    y) ;;
    n) mainHostName=$(trim "$OPTARG");;
    f) shareScript=$(trim "$OPTARG");;
    a) sharedPath=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version to install specified!"
  usage
  exit 1
fi

if [[ -z "${databaseHost}" ]]; then
  databaseHost="localhost"
fi

if [[ -z "${databasePort}" ]]; then
  databasePort="3306"
fi

if [[ -z "${databaseUser}" ]]; then
  echo "No database user to install specified!"
  usage
  exit 1
fi

if [[ -z "${databasePassword}" ]]; then
  echo "No database password to install specified!"
  usage
  exit 1
fi

if [[ -z "${databaseName}" ]]; then
  echo "No database name to install specified!"
  usage
  exit 1
fi

if [[ -z "${mainHostName}" ]]; then
  echo "No main host name to install data specified!"
  usage
  exit 1
fi

if [[ -z "${shareScript}" ]]; then
  echo "No share script to install data specified!"
  usage
  exit 1
fi

if [[ -z "${sharedPath}" ]]; then
  sharedPath="static"
fi

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
    -s "${sharedPath}" \
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
    -s "${sharedPath}" \
    -f app/etc/env.php \
    -o

  "${shareScript}" \
    -w "${webPath}" \
    -s "${sharedPath}" \
    -f app/etc/config.php \
    -o
fi

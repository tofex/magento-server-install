#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help              Show this message
  --magentoVersion    Magento version
  --cryptKey          Crypt key
  --databaseHost      Database host, default: localhost
  --databasePort      Database port, default: 3306
  --databaseUser      Database user
  --databasePassword  Database password
  --databaseName      Database name
  --webPath           Web path
  --mainHostName      Name of main host

Example: ${scriptName}
EOF
}

versionCompare() {
  if [[ "$1" == "$2" ]]; then
    echo "0"
  elif [[ "$1" = $(echo -e "$1\n$2" | sort -V | head -n1) ]]; then
    echo "1"
  else
    echo "2"
  fi
}

magentoVersion=
cryptKey=
databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=
webPath=
elasticsearchHost=
elasticsearchPort=
mainHostName=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

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
else
  rm -rf app/etc/env.php
  if [[ $(versionCompare "${magentoVersion}" "2.4.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "2.4.0") == 2 ]]; then
    if [[ -z "${elasticsearchHost}" ]]; then
      echo "No Elasticsearch host to install specified!"
      usage
      exit 1
    fi

    if [[ -z "${elasticsearchPort}" ]]; then
      echo "No Elasticsearch port to install specified!"
      usage
      exit 1
    fi

    bin/magento setup:install "--base-url=https://${mainHostName}/" "--base-url-secure=https://${mainHostName}/" \
      "--db-host=${databaseHost}:${databasePort}" "--db-name=${databaseName}" "--db-user=${databaseUser}" "--db-password=${databasePassword}" \
      --use-secure-admin=1 --backend-frontname=admin \
      --admin-lastname=Owner --admin-firstname=Store --admin-email=admin@tofex.de \
      --admin-user=admin --admin-password=adminadminadmin123 \
      --language=de_DE --currency=EUR --timezone=Europe/Berlin \
      --key "${cryptKey}" \
      --session-save=files --use-rewrites=1 \
      --elasticsearch-host "${elasticsearchHost}" \
      --elasticsearch-port "${elasticsearchPort}"
  else
    bin/magento setup:install "--base-url=https://${mainHostName}/" "--base-url-secure=https://${mainHostName}/" \
      "--db-host=${databaseHost}:${databasePort}" "--db-name=${databaseName}" "--db-user=${databaseUser}" "--db-password=${databasePassword}" \
      --use-secure-admin=1 --backend-frontname=admin \
      --admin-lastname=Owner --admin-firstname=Store --admin-email=admin@tofex.de \
      --admin-user=admin --admin-password=adminadminadmin123 \
      --language=de_DE --currency=EUR --timezone=Europe/Berlin \
      --key "${cryptKey}" \
      --session-save=files --use-rewrites=1
  fi
fi

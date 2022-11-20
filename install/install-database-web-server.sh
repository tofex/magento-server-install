#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help               Show this message
  --magentoVersion     Magento version
  --cryptKey           Crypt key
  --adminPath          Path of administration, default: admin
  --databaseHost       Database host, default: localhost
  --databasePort       Database port, default: 3306
  --databaseUser       Database user
  --databasePassword   Database password
  --databaseName       Database name
  --webPath            Web path
  --elasticsearchHost  Elasticsearch host
  --elasticsearchPort  Elasticsearch port
  --mainHostName       Name of main host
  --adminUser          User name of store admin, default: admin
  --adminPassword      Password of store admin, default: adminPassword12345
  --adminFirstName     First name of store admin, default: Store
  --adminLastName      Last name of store admin, default: Owner
  --adminEmail         E-Mail address of store admin, default: admin@tofex.com
  --defaultLocale      Language of store, default: de_DE
  --defaultCurrency    Currency of store, default: EUR
  --defaultTimezone    Timezone of store, default: Europe/Berlin

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
adminPath=
databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=
webPath=
elasticsearchHost=
elasticsearchPort=
mainHostName=
adminUser=
adminPassword=
adminFirstName=
adminLastName=
adminEmail=
defaultLocale=
defaultCurrency=
defaultTimezone=

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

if [[ -z "${cryptKey}" ]]; then
  echo "No crypt key to install specified!"
  usage
  exit 1
fi

if [[ -z "${adminPath}" ]]; then
  adminPath="admin"
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

if [[ -z "${adminUser}" ]]; then
  adminUser="admin"
fi

if [[ -z "${adminPassword}" ]]; then
  adminPassword="adminadminadmin123"
fi

if [[ -z "${adminFirstName}" ]]; then
  adminFirstName="Store"
fi

if [[ -z "${adminLastName}" ]]; then
  adminLastName="Owner"
fi

if [[ -z "${adminEmail}" ]]; then
  adminEmail="admin@tofex.com"
fi

if [[ -z "${defaultLocale}" ]]; then
  defaultLocale="de_DE"
fi

if [[ -z "${defaultCurrency}" ]]; then
  defaultCurrency="EUR"
fi

if [[ -z "${defaultTimezone}" ]]; then
  defaultTimezone="Europe/Berlin"
fi

cd "${webPath}"

if [[ ${magentoVersion:0:1} == 1 ]]; then
  rm -rf app/etc/local.xml
  php -f install.php -- --license_agreement_accepted yes \
    --db_host "${databaseHost}:${databasePort}" --db_name "${databaseName}" --db_user "${databaseUser}" --db_pass "${databasePassword}" \
    --url "https://${mainHostName}/" --skip_url_validation --use_rewrites yes \
    --use_secure yes --secure_base_url "https://${mainHostName}/" --use_secure_admin yes \
    --admin_username "${adminUser}" --admin_password "${adminPassword}" \
    --admin_firstname "${adminFirstName}" --admin_lastname "${adminLastName}" --admin_email "${adminEmail}" \
    --locale "${defaultLocale}" --default_currency "${defaultCurrency}" --timezone "${defaultTimezone}" \
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
      --use-secure-admin=1 --backend-frontname="${adminPath}" \
      --admin-user="${adminUser}" --admin-password="${adminPassword}" \
      --admin-firstname="${adminFirstName}" --admin-lastname="${adminLastName}" --admin-email="${adminEmail}" \
      --language="${defaultLocale}" --currency="${defaultCurrency}" --timezone="${defaultTimezone}" \
      --key "${cryptKey}" \
      --session-save=files --use-rewrites=1 \
      --elasticsearch-host "${elasticsearchHost}" \
      --elasticsearch-port "${elasticsearchPort}"
  else
    bin/magento setup:install "--base-url=https://${mainHostName}/" "--base-url-secure=https://${mainHostName}/" \
      "--db-host=${databaseHost}:${databasePort}" "--db-name=${databaseName}" "--db-user=${databaseUser}" "--db-password=${databasePassword}" \
      --use-secure-admin=1 --backend-frontname="${adminPath}" \
      --admin-user="${adminUser}" --admin-password="${adminPassword}" \
      --admin-firstname="${adminFirstName}" --admin-lastname="${adminLastName}" --admin-email="${adminEmail}" \
      --language="${defaultLocale}" --currency="${defaultCurrency}" --timezone="${defaultTimezone}" \
      --key "${cryptKey}" \
      --session-save=files --use-rewrites=1
  fi
fi

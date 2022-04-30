#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

database=
databaseHost=

for server in "${serverList[@]}"; do
  database=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "database")
  if [[ -n "${database}" ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${serverType}" == "local" ]]; then
      echo "--- Creating database user on local server: ${server} ---"
      databaseHost="localhost"
    else
      echo "--- Creating database user on remote server: ${server} ---"
      databaseHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
    fi
    break
  fi
done

if [[ -z "${databaseHost}" ]]; then
  echo "No database settings found"
  exit 1
fi

databasePort=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "port")
databaseUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "user")
databasePassword=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "password")
databaseName=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "name")

if [[ -z "${databasePort}" ]]; then
  echo "No database port specified!"
  exit 1
fi

if [[ -z "${databaseUser}" ]]; then
  echo "No database user specified!"
  exit 1
fi

if [[ -z "${databasePassword}" ]]; then
  echo "No database password specified!"
  exit 1
fi

if [[ -z "${databaseName}" ]]; then
  echo "No database name specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
cryptKey=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "cryptKey")

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  exit 1
fi

if [[ -z "${cryptKey}" ]]; then
  echo "No crypt key specified!"
  exit 1
fi

hostList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "host") )
if [[ "${#hostList[@]}" -eq 0 ]]; then
  echo "No hosts specified!"
  exit 1
fi

mainHostName=
for host in "${hostList[@]}"; do
  vhostList=( $(ini-parse "${currentPath}/../env.properties" "yes" "${host}" "vhost") )
  if [[ "${#hostList[@]}" -eq 0 ]]; then
    echo "No hosts specified!"
    exit 1
  fi
  mainHostName="${vhostList[0]}"
  break
done

if [[ -z "${mainHostName}" ]]; then
  echo "No main host found!"
  exit 1
fi

for server in "${serverList[@]}"; do
  type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
  if [[ "${type}" == "local" ]]; then
    webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
    echo "--- Installing Magento on local server: ${server} ---"
    "${currentPath}/../ops/cache-clean.sh"
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
      "${currentPath}/../ops/create-shared.sh" -f app/etc/local.xml -o
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
      "${currentPath}/../ops/create-shared.sh" -f app/etc/env.php -o
      "${currentPath}/../ops/create-shared.sh" -f app/etc/config.php -o
    fi
  fi
done

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

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

magentoEdition=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoEdition")
if [[ -z "${magentoEdition}" ]]; then
  echo "No magento edition specified!"
  exit 1
fi

database=
databaseHost=
databaseServerName=
databaseServerType=
for server in "${serverList[@]}"; do
  database=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "database")
  if [[ -n "${database}" ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${serverType}" == "local" ]]; then
      databaseHost="localhost"
      echo "--- Installing Magento demo DB data on local server: ${server} ---"
    else
      databaseHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      echo "--- Installing Magento demo DB data on remote server: ${server} ---"
    fi
    databaseServerName="${server}"
    databaseServerType="${serverType}"
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

if [[ "${databaseServerType}" == "local" ]]; then
  "${currentPath}/demo-local-db.sh" \
    -v "${magentoVersion}" \
    -e "${magentoEdition}" \
    -o "${databaseHost}" \
    -p "${databasePort}" \
    -u "${databaseUser}" \
    -w "${databasePassword}" \
    -b "${databaseName}" \
    -i "${currentPath}/../mysql/import-local.sh"
elif [[ "${databaseServerType}" == "ssh" ]]; then
  sshUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${databaseServerName}" "user")
  sshHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${databaseServerName}" "host")

  echo "Getting server fingerprint"
  ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts

  echo "Copying script to ${sshUser}@${databaseHost}:/tmp/mysql-import-local.sh"
  scp -q "${currentPath}/../mysql/import-local.sh" "${sshUser}@${databaseHost}:/tmp/mysql-import-local.sh"
  echo "Copying script to ${sshUser}@${databaseHost}:/tmp/demo-local-db.sh"
  scp -q "${currentPath}/demo-local-db.sh" "${sshUser}@${databaseHost}:/tmp/demo-local-db.sh"

  echo "Executing script at ${sshUser}@${sshHost}:/tmp/demo-local-db.sh"
  ssh "${sshUser}@${databaseHost}" "/tmp/demo-local-db.sh" \
    -v "${magentoVersion}" \
    -e "${magentoEdition}" \
    -o "${databaseHost}" \
    -p "${databasePort}" \
    -u "${databaseUser}" \
    -w "${databasePassword}" \
    -b "${databaseName}" \
    -i "/tmp/mysql-import-local.sh"

  echo "Removing script from: ${sshUser}@${sshHost}:/tmp/mysql-import-local.sh"
  ssh "${sshUser}@${databaseHost}" "rm -rf /tmp/mysql-import-local.sh"
  echo "Removing script from: ${sshUser}@${sshHost}:/tmp/demo-local-db.sh"
  ssh "${sshUser}@${databaseHost}" "rm -rf /tmp/demo-local-db.sh"
else
  echo "Invalid database server type: ${databaseServerType}"
  exit 1
fi

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")

    if [[ "${type}" == "local" ]]; then
      echo "--- Installing Magento demo web data on local server: ${server} ---"

      "${currentPath}/demo-local-web.sh" \
        -w "${webPath}" \
        -v "${magentoVersion}" \
        -e "${magentoEdition}" \
        -s "${currentPath}/../ops/create-shared-local.sh"
    elif [[ "${type}" == "ssh" ]]; then
      echo "--- Installing Magento demo web data on remote server: ${server} ---"
      sshUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "user")
      sshHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")

      echo "Getting server fingerprint"
      ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts

      echo "Copying script to ${sshUser}@${sshHost}:/tmp/ops-create-shared-local.sh"
      scp -q "${currentPath}/../ops/create-shared-local.sh" "${sshUser}@${sshHost}:/tmp/ops-create-shared-local.sh"
      echo "Copying script to ${sshUser}@${sshHost}:/tmp/demo-local-web.sh"
      scp -q "${currentPath}/demo-local-web.sh" "${sshUser}@${sshHost}:/tmp/demo-local-web.sh"

      echo "Executing script at ${sshUser}@${sshHost}:/tmp/demo-local-web.sh"
      ssh "${sshUser}@${sshHost}" /tmp/demo-local-web.sh \
        -w "${webPath}" \
        -v "${magentoVersion}" \
        -e "${magentoEdition}" \
        -s "/tmp/ops-create-shared-local.sh"

      echo "Removing script from: ${sshUser}@${sshHost}:/tmp/ops-create-shared-local.sh"
      ssh "${sshUser}@${sshHost}" "rm -rf /tmp/ops-create-shared-local.sh"
      echo "Removing script from: ${sshUser}@${sshHost}:/tmp/demo-local-web.sh"
      ssh "${sshUser}@${sshHost}" "rm -rf /tmp/demo-local-web.sh"
    fi

    break
  fi
done

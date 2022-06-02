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

"${currentPath}/../ops/cache-clean.sh"

database=
databaseHost=

for server in "${serverList[@]}"; do
  database=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "database")
  if [[ -n "${database}" ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${serverType}" == "local" ]]; then
      echo "--- Installing Magento with local database: ${server} ---"
      databaseHost="localhost"
    else
      echo "--- Installing Magento with remote database: ${server} ---"
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
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")

    if [[ "${serverType}" == "local" ]]; then
      echo "--- Installing Magento on local server: ${server} ---"

      "${currentPath}/install-local.sh" \
        -w "${webPath}" \
        -v "${magentoVersion}" \
        -o "${databaseHost}" \
        -p "${databasePort}" \
        -u "${databaseUser}" \
        -s "${databasePassword}" \
        -b "${databaseName}" \
        -m "${mainHostName}" \
        -c "${cryptKey}" \
        -f "${currentPath}/../ops/create-shared-local.sh"
    elif [[ "${serverType}" == "ssh" ]]; then
      echo "--- Installing Magento on remote server: ${server} ---"
      sshUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "user")
      sshHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")

      echo "Getting server fingerprint"
      ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts

      echo "Copying script to ${sshUser}@${sshHost}:/tmp/ops-create-shared-local.sh"
      scp -q "${currentPath}/../ops/create-shared-local.sh" "${sshUser}@${sshHost}:/tmp/ops-create-shared-local.sh"
      echo "Copying script to ${sshUser}@${sshHost}:/tmp/install-local.sh"
      scp -q "${currentPath}/install-local.sh" "${sshUser}@${sshHost}:/tmp/install-local.sh"

      echo "Executing script at ${sshUser}@${sshHost}:/tmp/install-local.sh"
      ssh "${sshUser}@${sshHost}" /tmp/install-local.sh \
        -w "${webPath}" \
        -v "${magentoVersion}" \
        -o "${databaseHost}" \
        -p "${databasePort}" \
        -u "${databaseUser}" \
        -s "${databasePassword}" \
        -b "${databaseName}" \
        -m "${mainHostName}" \
        -c "${cryptKey}" \
        -f "/tmp/ops-create-shared-local.sh"

      echo "Removing script from: ${sshUser}@${sshHost}:/tmp/ops-create-shared-local.sh"
      ssh "${sshUser}@${sshHost}" "rm -rf /tmp/ops-create-shared-local.sh"
      echo "Removing script from: ${sshUser}@${sshHost}:/tmp/install-local.sh"
      ssh "${sshUser}@${sshHost}" "rm -rf /tmp/install-local.sh"
    fi

    break
  fi
done

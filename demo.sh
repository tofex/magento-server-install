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

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      echo "--- Installing Magento demo data on local server: ${server} ---"
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")

      "${currentPath}/demo-local.sh" \
        -w "${webPath}" \
        -v "${magentoVersion}" \
        -e "${magentoEdition}" \
        -i "${currentPath}/../mysql/import.sh" \
        -s "${currentPath}/../ops/create-shared.sh"
    elif [[ "${type}" == "ssh" ]]; then
      echo "--- Installing Magento demo data on remote server: ${server} ---"
      sshUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "user")
      sshHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")

      echo "Getting server fingerprint"
      ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts

      echo "Copying script to ${sshUser}@${sshHost}:/tmp/demo-local.sh"
      scp -q "${currentPath}/demo-local.sh" "${sshUser}@${sshHost}:/tmp/demo-local.sh"
      echo "Copying script to ${sshUser}@${sshHost}:/tmp/mysql-import.sh"
      scp -q "${currentPath}/../mysql/import.sh" "${sshUser}@${sshHost}:/tmp/mysql-import.sh"
      echo "Copying script to ${sshUser}@${sshHost}:/tmp/ops-create-shared.sh"
      scp -q "${currentPath}/../ops/create-shared.sh" "${sshUser}@${sshHost}:/tmp/ops-create-shared.sh"

      echo "Executing script at ${sshUser}@${sshHost}:/tmp/demo-local.sh"
      ssh "${sshUser}@${sshHost}" /tmp/demo-local.sh \
        -w "${webPath}" \
        -v "${magentoVersion}" \
        -e "${magentoEdition}" \
        -i "/tmp/mysql-import.sh" \
        -s "/tmp/ops-create-shared.sh"

      echo "Removing script from: ${sshUser}@${sshHost}:/tmp/demo-local.sh"
      ssh "${sshUser}@${sshHost}" "rm -rf /tmp/demo-local.sh"
      echo "Removing script from: ${sshUser}@${sshHost}:/tmp/mysql-import.sh"
      ssh "${sshUser}@${sshHost}" "rm -rf /tmp/mysql-import.sh"
      echo "Removing script from: ${sshUser}@${sshHost}:/tmp/ops-create-shared.sh"
      ssh "${sshUser}@${sshHost}" "rm -rf /tmp/ops-create-shared.sh"
    fi
  fi
done

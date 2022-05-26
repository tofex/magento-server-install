#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -o  Overwrite existing files (Optional)

Example: ${scriptName} -o
EOF
}

trim()
{
  echo -n "$1" | xargs
}

overwrite=0

while getopts ho? option; do
  case "${option}" in
    h) usage; exit 1;;
    o) overwrite=1;;
    ?) usage; exit 1;;
  esac
done

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

repositoryList=( $(ini-parse "${currentPath}/../env.properties" "yes" "install" "repositories") )
magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
magentoEdition=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoEdition")
magentoMode=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoMode")

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  exit 1
fi

if [[ -z "${magentoEdition}" ]]; then
  echo "No Magento edition specified!"
  exit 1
fi

if [[ -z "${magentoMode}" ]]; then
  echo "No Magento mode specified!"
  exit 1
fi

if [[ "${#repositoryList[@]}" -eq 0 ]]; then
  echo "No composer repositories specified!"
  exit 1
fi

repositories=$(IFS=,; printf '%s' "${repositoryList[*]}")

downloaded=0

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")

    if [[ "${type}" == "local" ]]; then
      echo "--- Downloading on local server: ${server} ---"

      if [[ "${overwrite}" == 1 ]]; then
        "${currentPath}/download-local.sh" \
          -w "${webPath}" \
          -r "${repositories}" \
          -v "${magentoVersion}" \
          -e "${magentoEdition}" \
          -o
      else
        "${currentPath}/download-local.sh" \
          -w "${webPath}" \
          -r "${repositories}" \
          -v "${magentoVersion}" \
          -e "${magentoEdition}"
      fi

      downloaded=1
    elif [[ "${type}" == "ssh" ]]; then
      echo "--- Downloading on remote server: ${server} ---"
      sshUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "user")
      sshHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")

      echo "Getting server fingerprint"
      ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts

      echo "Copying download script to ${sshUser}@${sshHost}:/tmp/download-local.sh"
      scp -q "${currentPath}/download-local.sh" "${sshUser}@${sshHost}:/tmp/download-local.sh"
      echo "Executing script at ${sshUser}@${sshHost}:/tmp/download-local.sh"
      if [[ "${overwrite}" == 1 ]]; then
        ssh "${sshUser}@${sshHost}" /tmp/download-local.sh \
          -w "${webPath}" \
          -r "\"${repositories}\"" \
          -v "${magentoVersion}" \
          -e "${magentoEdition}" \
          -o
      else
        ssh "${sshUser}@${sshHost}" /tmp/download-local.sh \
          -w "${webPath}" \
          -r "\"${repositories}\"" \
          -v "${magentoVersion}" \
          -e "${magentoEdition}"
      fi

      downloaded=1
    fi
  fi
done

if [[ "${downloaded}" == 0 ]]; then
  echo "Found no webservers to download to"
  exit 1
fi

if [[ ${magentoVersion:0:1} == 1 ]]; then
  "${currentPath}/../ops/create-shared.sh" \
    -f media \
    -o
  "${currentPath}/../ops/create-shared.sh" \
    -f var \
    -o
else
  if [[ "${magentoMode}" == "production" ]]; then
    "${currentPath}/../ops/create-shared.sh" \
      -f generated \
      -o
    echo "!!! Generated code folder is setup as symlink. Do not compile without real deployment process. !!!"
  fi
  "${currentPath}/../ops/create-shared.sh" \
    -f pub/media \
    -o
  "${currentPath}/../ops/create-shared.sh" \
    -f pub/static \
    -o
  "${currentPath}/../ops/create-shared.sh" \
    -f var \
    -o
fi

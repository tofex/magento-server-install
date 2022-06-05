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

executeScript()
{
  local serverName="${1}"
  shift
  local filePath="${1}"
  shift
  local parameters=("$@")

  echo "--- Executing script at: ${filePath} on local server: ${serverName} ---"
  "${filePath}" "${parameters[@]}"
}

executeScriptWithSSH()
{
  local serverName="${1}"
  shift
  local sshUser="${1}"
  shift
  local sshHost="${1}"
  shift
  local filePath="${1}"
  shift
  local parameters=("$@")

  copyFileToSSH "${sshUser}" "${sshHost}" "${filePath}"

  local fileName
  fileName=$(basename "${filePath}")
  local remoteFileName="/tmp/${fileName}"

  echo "--- Executing script at: ${filePath} on remote server: ${serverName} [${sshUser}@${sshHost}] at: ${remoteFileName} ---"
  ssh "${sshUser}@${sshHost}" "${remoteFileName}" "${parameters[@]}"

  removeFileFromSSH "${sshUser}" "${sshHost}" "${remoteFileName}"
}

copyFileToSSH()
{
  local sshUser="${1}"
  local sshHost="${2}"
  local filePath="${3}"

  local fileName
  fileName=$(basename "${filePath}")
  local remoteFileName="/tmp/${fileName}"

  echo "Getting server fingerprint"
  ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts 2>/dev/null

  echo "Copying file from: ${filePath} to: ${sshUser}@${sshHost}:${remoteFileName}"
  scp -q "${filePath}" "${sshUser}@${sshHost}:${remoteFileName}"
}

removeFileFromSSH()
{
  local sshUser="${1}"
  local sshHost="${2}"
  local filePath="${3}"

  echo "Getting server fingerprint"
  ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts 2>/dev/null

  echo "Removing file from: ${sshUser}@${sshHost}:${filePath}"
  ssh "${sshUser}@${sshHost}" "rm -rf ${filePath}"
}

overwrite="no"

while getopts ho? option; do
  case "${option}" in
    h) usage; exit 1;;
    o) overwrite="yes";;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

magentoMode=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoMode")
if [[ -z "${magentoMode}" ]]; then
  echo "No magento mode specified!"
  exit 1
fi

"${currentPath}/../core/script/web-server/all.sh" "${currentPath}/web-server/web-server-root.sh"
"${currentPath}/../core/script/web-server/all.sh" "${currentPath}/web-server/web-server-path.sh"
"${currentPath}/../core/script/web-server/all.sh" "${currentPath}/web-server/web-server-log.sh"
"${currentPath}/../core/script/web-server/all.sh" "${currentPath}/web-server/[webServerType]/[webServerVersion]/web-server-log.sh"
"${currentPath}/../core/script/host/web-servers.sh" "${currentPath}/web-server/host-web-server-basic-auth.sh"
"${currentPath}/../core/script/host/web-servers.sh" "${currentPath}/web-server/[webServerType]/[webServerVersion]/host-web-server-magento${magentoVersion:0:1}.sh" \
  -m "${magentoMode}" \
  -j "${overwrite}"

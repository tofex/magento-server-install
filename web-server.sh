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
  -m "${magentoVersion}" \
  -d "${magentoMode}" \
  -j "${overwrite}"

if [[ $(versionCompare "${magentoVersion}" "2.2.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "2.2.0") == 2 ]]; then
  "${currentPath}/../config/document-root.sh"
fi

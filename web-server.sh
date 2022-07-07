#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -n  Install only this host (Optional)
  -o  Overwrite existing files (Optional)

Example: ${scriptName} -o
EOF
}

trim()
{
  echo -n "$1" | xargs
}

hostName=
overwrite="no"

while getopts hn:o? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) hostName=$(trim "$OPTARG");;
    o) overwrite="yes";;
    ?) usage; exit 1;;
  esac
done

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

"${currentPath}/../core/script/run.sh" "webServer:all" "${currentPath}/web-server/web-server-root.sh"
"${currentPath}/../core/script/run.sh" "webServer:all" "${currentPath}/web-server/web-server-path.sh"
"${currentPath}/../core/script/run.sh" "webServer:all" "${currentPath}/web-server/web-server-log.sh"
"${currentPath}/../core/script/run.sh" "webServer:all" "${currentPath}/web-server/[webServerType]/[webServerVersion]/web-server-log.sh"

if [[ -n "${hostName}" ]] && [[ "${hostName}" != "-" ]]; then
  "${currentPath}/../core/script/run.sh" "host:${hostName},webServer:all" "${currentPath}/web-server/host-web-server-basic-auth.sh"
  "${currentPath}/../core/script/run.sh" "install,host:${hostName},webServer:all" "${currentPath}/web-server/[webServerType]/[webServerVersion]/host-web-server-magento${magentoVersion:0:1}.sh" \
    --overwrite "${overwrite}"
else
  "${currentPath}/../core/script/run.sh" "host:all,webServer:all" "${currentPath}/web-server/host-web-server-basic-auth.sh"
  "${currentPath}/../core/script/run.sh" "install,host:all,webServer:all" "${currentPath}/web-server/[webServerType]/[webServerVersion]/host-web-server-magento${magentoVersion:0:1}.sh" \
    --overwrite "${overwrite}"
fi

"${currentPath}/../config/document-root.sh"

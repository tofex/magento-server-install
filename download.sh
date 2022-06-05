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

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

if [[ "${overwrite}" == 1 ]]; then
  "${currentPath}/../core/script/magento/web-servers.sh" "${currentPath}/download/magento-web-server.sh" -o
else
  "${currentPath}/../core/script/magento/web-servers.sh" "${currentPath}/download/magento-web-server.sh"
fi

"${currentPath}/../core/script/system/magento.sh" "${currentPath}/download/magento.sh"

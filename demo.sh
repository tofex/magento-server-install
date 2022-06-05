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

"${currentPath}/../core/script/magento/database.sh" "${currentPath}/demo/database.sh" \
  -i "script:${currentPath}/../mysql/import/database.sh"

"${currentPath}/../core/script/magento/web-servers.sh" "${currentPath}/demo/magento.sh" \
  -s "script:${currentPath}/../ops/create-shared/web-server.sh"

#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

"${currentPath}/../core/script/magento/database.sh" "${currentPath}/demo/database.sh" \
  -i "script:${currentPath}/../mysql/import/database.sh"

"${currentPath}/../core/script/magento/web-servers.sh" "${currentPath}/demo/magento.sh" \
  -s "script:${currentPath}/../ops/create-shared/web-server.sh"

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  fileName="skin/frontend/rwd/default/images/media"
else
  fileName="app/code/Magento"
fi

"${currentPath}/../core/script/env/web-servers.sh" "${currentPath}/../ops/create-shared/env-web-server.sh" \
  -f "${fileName}" \
  -s "static"

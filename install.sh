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

mainHostName=$("${currentPath}/../core/server/host/single.sh")

"${currentPath}/../core/script/magento/database/web-server.sh" "${currentPath}/install/magento.sh" \
  -n "${mainHostName}" \
  -f "script:${currentPath}/../ops/create-shared/web-server.sh"

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  "${currentPath}/../core/script/env/web-servers.sh" "${currentPath}/../ops/create-shared/env-web-server.sh" \
    -f "app/etc/local.xml" \
    -s "static"
else
  "${currentPath}/../core/script/env/web-servers.sh" "${currentPath}/../ops/create-shared/env-web-server.sh" \
    -f "app/etc/env.php" \
    -s "static"

  "${currentPath}/../core/script/env/web-servers.sh" "${currentPath}/../ops/create-shared/env-web-server.sh" \
    -f "app/etc/config.php" \
    -s "static"
fi

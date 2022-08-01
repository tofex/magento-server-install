#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mainHostName=$("${currentPath}/../core/server/host/admin.sh" | cat)

if [[ -z "${mainHostName}" ]]; then
  mainHostName=$("${currentPath}/../core/server/host/single.sh")
fi

"${currentPath}/../core/script/run.sh" "install,database,webServer" "${currentPath}/install/install-database-web-server.sh" \
  --mainHostName "${mainHostName}"

"${currentPath}/../core/script/run.sh" "install" "${currentPath}/install/install.sh"

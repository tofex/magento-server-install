#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"${currentPath}/../core/script/run.sh" "install,database" "${currentPath}/demo/install-database.sh" \
  --importScript "script:${currentPath}/../mysql/import/database.sh"

"${currentPath}/../core/script/run.sh" "install,webServer" "${currentPath}/demo/install-web-server.sh"

"${currentPath}/../core/script/run.sh" "install:local" "${currentPath}/demo/install.sh"

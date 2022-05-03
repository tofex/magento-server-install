#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../../../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../../../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  serverType=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${server}" "type")
  elasticsearch=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${server}" "elasticsearch")
  if [[ -n "${elasticsearch}" ]]; then
    if [[ "${serverType}" == "local" ]]; then
      echo "--- Installing Elasticsearch suite on local server: ${server} ---"
      "${currentPath}/suite-local.sh"
    else
      echo "--- Installing Elasticsearch suite on remote server: ${server} ---"
    fi
  fi
done

#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

elasticsearchVersion=
for server in "${serverList[@]}"; do
  elasticsearch=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "elasticsearch")
  if [[ -n "${elasticsearch}" ]]; then
    elasticsearchVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${elasticsearch}" "version")
  fi
done

if [[ -z "${elasticsearchVersion}" ]]; then
  echo "No Elasticsearch version specified!"
  exit 1
fi

elasticsearchScript="${currentPath}/${elasticsearchVersion}/suite.sh"

if [[ ! -f "${elasticsearchScript}" ]]; then
  echo "Missing Elasticsearch script: ${elasticsearchScript}"
  exit 1
fi

"${elasticsearchScript}"

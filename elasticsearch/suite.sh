#!/bin/bash -e

versionCompare() {
  if [[ "$1" == "$2" ]]; then
    echo "0"
  elif [[ "$1" = $(echo -e "$1\n$2" | sort -V | head -n1) ]]; then
    echo "1"
  else
    echo "2"
  fi
}

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

magentoVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

if [[ $(versionCompare "${magentoVersion}" "7.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "7.0") == 2 ]]; then
  elasticsearchScript="${currentPath}/${elasticsearchVersion}/suite.sh"

  if [[ ! -f "${elasticsearchScript}" ]]; then
    echo "Missing Elasticsearch script: ${elasticsearchScript}"
    exit 1
  fi

  "${elasticsearchScript}"
else
  echo "Elasticsearch ${elasticsearchVersion} requires no suite plugins"
fi

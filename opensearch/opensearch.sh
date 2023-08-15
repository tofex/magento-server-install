#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help               Show this message
  --openSearchVersion  OpenSearch version

Example: ${scriptName} --openSearchVersion 2.9
EOF
}

versionCompare() {
  if [[ "$1" == "$2" ]]; then
    echo "0"
  elif [[ "$1" = $(echo -e "$1\n$2" | sort -V | head -n1) ]]; then
    echo "1"
  else
    echo "2"
  fi
}

openSearchVersion=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${openSearchVersion}" ]]; then
  echo "No OpenSearch version specified!"
  exit 1
fi

cd /opt/opensearch

if [[ $(sudo bin/opensearch-plugin list | grep "analysis-phonetic" | wc -l) -eq 0 ]]; then
  echo "Installing OpenSearch plugin: analysis-phonetic"
  sudo bin/opensearch-plugin install analysis-phonetic
else
  echo "OpenSearch plugin: analysis-phonetic already installed"
fi

if [[ $(sudo bin/opensearch-plugin list | grep "analysis-icu" | wc -l) -eq 0 ]]; then
  echo "Installing OpenSearch plugin: analysis-icu"
  sudo bin/opensearch-plugin install analysis-icu
else
  echo "OpenSearch plugin: analysis-icu already installed"
fi

if [[ ! -f /.dockerenv ]]; then
  echo "Restarting OpenSearch"
  sudo service opensearch restart
fi

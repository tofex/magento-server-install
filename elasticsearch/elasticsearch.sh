#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                  Show this message
  --elasticsearchVersion  Elasticsearch version

Example: ${scriptName} --elasticsearchVersion 7.9
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

elasticsearchVersion=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${elasticsearchVersion}" ]]; then
  echo "No Elasticsearch version specified!"
  exit 1
fi

if [[ $(versionCompare "${elasticsearchVersion}" "7.0") == 0 ]] || [[ $(versionCompare "${elasticsearchVersion}" "7.0") == 2 ]]; then
  cd /usr/share/elasticsearch

  echo "Installing Elasticsearch plugin: analysis-phonetic"
  sudo bin/elasticsearch-plugin install analysis-phonetic

  echo "Installing Elasticsearch plugin: analysis-icu"
  sudo bin/elasticsearch-plugin install analysis-icu

  if [[ ! -f /.dockerenv ]]; then
    echo "Restarting Elasticsearch"
    sudo service elasticsearch restart
  fi
fi

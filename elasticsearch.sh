#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

while getopts h? option; do
  case ${option} in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

"${currentPath}/../core/script/run.sh" "elasticsearch:all" "${currentPath}/elasticsearch/elasticsearch.sh"

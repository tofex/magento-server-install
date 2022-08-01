#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -o  Overwrite existing files (Optional)

Example: ${scriptName} -o
EOF
}

trim()
{
  echo -n "$1" | xargs
}

overwrite="no"

while getopts ho? option; do
  case "${option}" in
    h) usage; exit 1;;
    o) overwrite="yes";;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"${currentPath}/../core/script/run.sh" "install,webServer:all" "${currentPath}/download/install-web-server.sh" \
  --overwrite "${overwrite}"

"${currentPath}/../core/script/run.sh" "install" "${currentPath}/download/install.sh"

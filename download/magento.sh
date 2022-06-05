#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Magento version
  -d  Magento mode

Example: ${scriptName} -m 2.3.7 -d production
EOF
}

trim()
{
  echo -n "$1" | xargs
}

magentoVersion=
magentoMode=

while getopts hm:e:d:r:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) ;;
    d) magentoMode=$(trim "$OPTARG");;
    r) ;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version to download specified!"
  exit 1
fi

if [[ -z "${magentoMode}" ]]; then
  echo "No Magento edition to download specified!"
  exit 1
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ${magentoVersion:0:1} == 1 ]]; then
  "${currentPath}/../../ops/create-shared.sh" \
    -f media \
    -o
  "${currentPath}/../../ops/create-shared.sh" \
    -f var \
    -o
else
  if [[ "${magentoMode}" == "production" ]]; then
    "${currentPath}/../../ops/create-shared.sh" \
      -f generated \
      -o
    echo "!!! Generated code folder is setup as symlink. Do not compile without real deployment process. !!!"
  fi
  "${currentPath}/../../ops/create-shared.sh" \
    -f pub/media \
    -o
  "${currentPath}/../../ops/create-shared.sh" \
    -f pub/static \
    -o
  "${currentPath}/../../ops/create-shared.sh" \
    -f var \
    -o
fi

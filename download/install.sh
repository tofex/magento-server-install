#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help            Show this message
  --magentoVersion  Magento version
  --magentoMode     Magento mode

Example: ${scriptName} --magentoVersion 2.3.7 --magentoMode production
EOF
}

trim()
{
  echo -n "$1" | xargs
}

magentoVersion=
magentoMode=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version to download specified!"
  exit 1
fi

if [[ -z "${magentoMode}" ]]; then
  echo "No Magento edition to download specified!"
  exit 1
fi

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

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

Example: ${scriptName} --magentoVersion 2.3.7
EOF
}

magentoVersion=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version to install demo data specified!"
  exit 1
fi

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  fileName="skin/frontend/rwd/default/images/media"
else
  fileName="app/code/Magento"
fi

"${currentPath}/../../ops/create-shared.sh" \
  -f "${fileName}" \
  -o

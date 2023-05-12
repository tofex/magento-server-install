#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help             Show this message
  --magentoVersion   Magento version
  --magentoMode      Magento mode
  --adminPath        Path of administration, default: admin
  --adminUser        User name of store admin, default: admin
  --adminPassword    Password of store admin, default: adminPassword12345
  --adminFirstName   First name of store admin, default: Store
  --adminLastName    Last name of store admin, default: Owner
  --adminEmail       E-Mail address of store admin, default: admin@tofex.com
  --defaultLocale    Language of store, default: de_DE
  --defaultCurrency  Currency of store, default: EUR
  --defaultTimezone  Timezone of store, default: Europe/Berlin

Example: ${scriptName} --magentoVersion 2.3.7 --magentoMode production
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

magentoVersion=
magentoMode=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version to install specified!"
  exit 1
fi

if [[ -z "${magentoMode}" ]]; then
  echo "No Magento edition to install specified!"
  exit 1
fi

if [[ $(versionCompare "${magentoVersion}" "2.0.0") == 1 ]]; then
  "${currentPath}/../../ops/create-shared.sh" \
    -f app/etc/local.xml \
    -o
elif [[ $(versionCompare "${magentoVersion}" "19.1.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "19.1.0") == 2 ]]; then
  "${currentPath}/../../ops/create-shared.sh" \
    -f app/etc/local.xml \
    -o
else
  "${currentPath}/../../ops/create-shared.sh" \
    -f app/etc/env.php \
    -o
  "${currentPath}/../../ops/create-shared.sh" \
    -f app/etc/config.php \
    -o
fi

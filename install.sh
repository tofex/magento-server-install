#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help               Show this message
  --adminUser          User name of store admin, default: admin
  --adminPassword      Password of store admin, default: adminPassword12345
  --adminFirstName     First name of store admin, default: Store
  --adminLastName      Last name of store admin, default: Owner
  --adminEmail         E-Mail address of store admin, default: admin@tofex.com
  --defaultLocale      Language of store, default: de_DE
  --defaultCurrency    Currency of store, default: EUR
  --defaultTimezone    Timezone of store, default: Europe/Berlin

Example: ${scriptName}
EOF
}

if [[ -f "${currentPath}/../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${adminUser}" ]]; then
  adminUser="admin"
fi

if [[ -z "${adminPassword}" ]]; then
  adminPassword="adminadminadmin123"
fi

if [[ -z "${adminFirstName}" ]]; then
  adminFirstName="Store"
fi

if [[ -z "${adminLastName}" ]]; then
  adminLastName="Owner"
fi

if [[ -z "${adminEmail}" ]]; then
  adminEmail="admin@tofex.com"
fi

if [[ -z "${defaultLocale}" ]]; then
  defaultLocale="de_DE"
fi

if [[ -z "${defaultCurrency}" ]]; then
  defaultCurrency="EUR"
fi

if [[ -z "${defaultTimezone}" ]]; then
  defaultTimezone="Europe/Berlin"
fi

mainHostName=$("${currentPath}/../core/server/host/admin.sh" | cat)

if [[ -z "${mainHostName}" ]]; then
  mainHostName=$("${currentPath}/../core/server/host/single.sh")
fi

"${currentPath}/../core/script/run.sh" "install,database,elasticsearch:skip,openSearch:skip,webServer" "${currentPath}/install/install-database-web-server.sh" \
  --mainHostName "${mainHostName}" \
  --adminUser "${adminUser}" \
  --adminPassword "${adminPassword}" \
  --adminFirstName "${adminFirstName}" \
  --adminLastName "${adminLastName}" \
  --adminEmail "${adminEmail}" \
  --defaultLocale "${defaultLocale}" \
  --defaultCurrency "${defaultCurrency}" \
  --defaultTimezone "${defaultTimezone}"

"${currentPath}/../core/script/run.sh" "install:local" "${currentPath}/install/install.sh"

#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help      Show this message
  --webPath   Web path
  --webUser   Web user, default: www-data
  --webGroup  Web group, default: www-data

Example: ${scriptName} --webPath /var/www/magento/htdocs
EOF
}

webPath=
webUser=
webGroup=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  usage
  exit 1
fi

if [[ -z "${webUser}" ]]; then
  webUser="www-data"
fi

if [[ -z "${webGroup}" ]]; then
  webGroup="www-data"
fi

webRoot=$(dirname "${webPath}")
currentUser="$(whoami)"
currentGroup="$(id -g -n)"

if [[ ! -d "${webRoot}/log" ]]; then
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    result=$(sudo -H -u "${webUser}" bash -c "mkdir -p ${webRoot}/log/" 2>/dev/null && echo "1" || echo "0")
    if [[ "${result}" -eq 0 ]]; then
      result=$(sudo -H -u "${webUser}" bash -c "sudo mkdir -p ${webRoot}/log/" 2>/dev/null && echo "1" || echo "0")
      if [[ "${result}" -eq 0 ]]; then
        sudo mkdir -p "${webRoot}/log/"
        sudo chown "${webUser}":"${webGroup}" "${webRoot}/log/"
      else
        sudo -H -u "${webUser}" bash -c "sudo chown ${webUser}:${webGroup} ${webRoot}/log/"
      fi
    fi
  else
    result=$(mkdir -p "${webRoot}/log/" 2>/dev/null && echo "1" || echo "0")
    if [[ "${result}" -eq 0 ]]; then
      sudo mkdir -p "${webRoot}/log/"
      sudo chown "${webUser}":"${webGroup}" "${webRoot}/log/"
    fi
  fi
fi

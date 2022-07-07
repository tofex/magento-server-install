#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help               Show this message
  --webPath            Web path
  --webUser            Web user, default: www-data
  --webGroup           Web group, default: www-data
  --hostName           Host name
  --basicAuthUserName  Basic auth user name
  --basicAuthPassword  Basic auth password

Example: ${scriptName} --webPath /var/www/magento/htdocs --hostName dev_magento2_de --basicAuthUserName letme --basicAuthPassword in
EOF
}

webPath=
webUser=
webGroup=
hostName=
basicAuthUserName=
basicAuthPassword=

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

if [[ -z "${hostName}" ]]; then
  echo "No host name specified!"
  usage
  exit 1
fi

webRoot=$(dirname "${webPath}")
currentUser="$(whoami)"
currentGroup="$(id -g -n)"

if [[ -n "${basicAuthUserName}" ]] && [[ "${basicAuthUserName}" != "-" ]]; then
  echo "Adding basic user in file at: ${webRoot}/${hostName}.htpasswd"
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    if [[ -f "${webRoot}/${hostName}.htpasswd" ]]; then
      result=$(sudo -H -u "${webUser}" bash -c "htpasswd -b \"${webRoot}/${hostName}.htpasswd\" \"${basicAuthUserName}\" \"${basicAuthPassword}\"" 2>/dev/null && echo "1" || echo "0")
      if [[ "${result}" -eq 0 ]]; then
        sudo -H -u "${webUser}" bash -c "sudo htpasswd -b \"${webRoot}/${hostName}.htpasswd\" \"${basicAuthUserName}\" \"${basicAuthPassword}\""
      fi
    else
      result=$(sudo -H -u "${webUser}" bash -c "htpasswd -b -c \"${webRoot}/${hostName}.htpasswd\" \"${basicAuthUserName}\" \"${basicAuthPassword}\"" 2>/dev/null && echo "1" || echo "0")
      if [[ "${result}" -eq 0 ]]; then
        sudo -H -u "${webUser}" bash -c "sudo htpasswd -b -c \"${webRoot}/${hostName}.htpasswd\" \"${basicAuthUserName}\" \"${basicAuthPassword}\""
      fi
    fi
  else
    if [[ -f "${webRoot}/${hostName}.htpasswd" ]]; then
      result=$(htpasswd -b "${webRoot}/${hostName}.htpasswd" "${basicAuthUserName}" "${basicAuthPassword}" 2>/dev/null && echo "1" || echo "0")
      if [[ "${result}" -eq 0 ]]; then
        sudo htpasswd -b "${webRoot}/${hostName}.htpasswd" "${basicAuthUserName}" "${basicAuthPassword}"
      fi
    else
      result=$(htpasswd -b -c "${webRoot}/${hostName}.htpasswd" "${basicAuthUserName}" "${basicAuthPassword}" 2>/dev/null && echo "1" || echo "0")
      if [[ "${result}" -eq 0 ]]; then
        sudo htpasswd -b -c "${webRoot}/${hostName}.htpasswd" "${basicAuthUserName}" "${basicAuthPassword}"
      fi
    fi
  fi
else
  echo "No basic auth required"
fi

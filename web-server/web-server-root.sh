#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -w  Web path
  -u  Web user, default: www-data
  -g  Web group, default: www-data

Example: ${scriptName} -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

webPath=
webUser=
webGroup=

while getopts hn:w:u:g:t:v:p:z:x:y:? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) ;;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    ?) usage; exit 1;;
  esac
done

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

if [[ ! -d "${webRoot}" ]]; then
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    result=$(sudo -H -u "${webUser}" bash -c "mkdir -p ${webRoot}" 2>/dev/null && echo "1" || echo "0")
    if [[ "${result}" -eq 0 ]]; then
      result=$(sudo -H -u "${webUser}" bash -c "sudo mkdir -p ${webRoot}" 2>/dev/null && echo "1" || echo "0")
      if [[ "${result}" -eq 0 ]]; then
        sudo mkdir -p "${webRoot}"
        sudo chown "${webUser}":"${webGroup}" "${webRoot}"
      else
        sudo -H -u "${webUser}" bash -c "sudo chown ${webUser}:${webGroup} ${webRoot}"
      fi
    fi
  else
    result=$(mkdir -p "${webRoot}" 2>/dev/null && echo "1" || echo "0")
    if [[ "${result}" -eq 0 ]]; then
      sudo mkdir -p "${webRoot}"
      sudo chown "${webUser}":"${webGroup}" "${webRoot}"
    fi
  fi
fi

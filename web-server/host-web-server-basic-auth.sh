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
  -n  Host name
  -b  Basic auth user name
  -s  Basic auth password

Example: ${scriptName} -w /var/www/magento/htdocs -n dev_magento2_de -b letme -s in
EOF
}

trim()
{
  echo -n "$1" | xargs
}

webPath=
webUser=
webGroup=
hostName=
basicAuthUserName=
basicAuthPassword=

while getopts hw:u:g:t:v:p:z:x:y:n:o:a:e:c:l:k:r:f:i:b:s:? option; do
  case "${option}" in
    h) usage; exit 1;;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    n) hostName=$(trim "$OPTARG");;
    o) ;;
    a) ;;
    e) ;;
    c) ;;
    l) ;;
    k) ;;
    r) ;;
    f) ;;
    i) ;;
    b) basicAuthUserName=$(trim "$OPTARG");;
    s) basicAuthPassword=$(trim "$OPTARG");;
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

if [[ -z "${hostName}" ]]; then
  echo "No host name specified!"
  usage
  exit 1
fi

webRoot=$(dirname "${webPath}")
currentUser="$(whoami)"
currentGroup="$(id -g -n)"

if [[ -n "${basicAuthUserName}" ]] && [[ "${basicAuthUserName}" != "-" ]]; then
  echo "Adding basic user in file at: ${webRoot}/.htpasswd"
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    if [[ -f "${webRoot}/.htpasswd" ]]; then
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
    if [[ -f "${webRoot}/.htpasswd" ]]; then
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

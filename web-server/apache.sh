#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -w  Web server name
  -o  Overwrite existing files (Optional)

Example: ${scriptName} -t yes -f no
EOF
}

trim()
{
  echo -n "$1" | xargs
}

serverType=
sshUser=
sshHost=
webPath=
webServer=
overwrite=0

while getopts hs:u:t:p:w:o? option; do
  case ${option} in
    h) usage; exit 1;;
    s) serverType=$(trim "$OPTARG");;
    u) sshUser=$(trim "$OPTARG");;
    t) sshHost=$(trim "$OPTARG");;
    p) webPath=$(trim "$OPTARG");;
    w) webServer=$(trim "$OPTARG");;
    o) overwrite=1;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${serverType}" ]]; then
  echo "No server type specified!"
  exit 1
fi

if [[ "${serverType}" == "ssh" ]] && [[ -z "${sshUser}" ]]; then
  echo "No SSH user specified!"
  exit 1
fi

if [[ "${serverType}" == "ssh" ]] && [[ -z "${sshHost}" ]]; then
  echo "No SSH host specified!"
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ -z "${sshUser}" ]]; then
  sshUser="-"
fi

if [[ -z "${sshHost}" ]]; then
  sshHost="-"
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f ${currentPath}/../../env.properties ]]; then
  echo "No environment specified!"
  exit 1
fi

apacheVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${webServer}" "version")
apacheHttpPort=$(ini-parse "${currentPath}/../../env.properties" "yes" "${webServer}" "httpPort")
apacheSslPort=$(ini-parse "${currentPath}/../../env.properties" "yes" "${webServer}" "sslPort")

if [[ -z "${apacheHttpPort}" ]]; then
  echo "No Apache HTTP port specified!"
  exit 1
fi

if [[ -z "${apacheSslPort}" ]]; then
  echo "No Apache SSL port specified!"
  exit 1
fi

if [[ -z "${apacheVersion}" ]]; then
  echo "No Apache version specified!"
  exit 1
fi

apacheScript="${currentPath}/apache/${apacheVersion}/install.sh"
if [[ ! -f "${apacheScript}" ]]; then
  echo "Missing Apache script: ${apacheScript}"
  exit 1
fi

hostList=( $(ini-parse "${currentPath}/../../env.properties" "yes" "system" "host") )
if [[ "${#hostList[@]}" -eq 0 ]]; then
  echo "No hosts specified!"
  exit 1
fi

for host in "${hostList[@]}"; do
  vhostList=( $(ini-parse "${currentPath}/../../env.properties" "yes" "${host}" "vhost") )
  scope=$(ini-parse "${currentPath}/../../env.properties" "yes" "${host}" "scope")
  code=$(ini-parse "${currentPath}/../../env.properties" "yes" "${host}" "code")
  sslCertFile=$(ini-parse "${currentPath}/../../env.properties" "no" "${host}" "sslCertFile")
  sslKeyFile=$(ini-parse "${currentPath}/../../env.properties" "no" "${host}" "sslKeyFile")
  sslTerminated=$(ini-parse "${currentPath}/../../env.properties" "no" "${host}" "sslTerminated")
  forceSsl=$(ini-parse "${currentPath}/../../env.properties" "no" "${host}" "forceSsl")
  requireIpList=( $(ini-parse "${currentPath}/../../env.properties" "no" "${host}" "requireIp") )
  basicAuthUserName=$(ini-parse "${currentPath}/../../env.properties" "no" "${host}" "basicAuthUserName")
  basicAuthPassword=$(ini-parse "${currentPath}/../../env.properties" "no" "${host}" "basicAuthPassword")
  if [[ -z "${sslCertFile}" ]]; then
    sslCertFile="/etc/ssl/certs/ssl-cert-snakeoil.pem"
  fi
  if [[ -z "${sslKeyFile}" ]]; then
    sslKeyFile="/etc/ssl/private/ssl-cert-snakeoil.key"
  fi
  if [[ -z "${sslTerminated}" ]]; then
    sslTerminated="no"
  fi
  if [[ "${sslTerminated}" == 0 ]]; then
    sslTerminated="no"
  fi
  if [[ "${sslTerminated}" == 1 ]]; then
    sslTerminated="yes"
  fi
  if [[ -z "${forceSsl}" ]]; then
    forceSsl="yes"
  fi
  if [[ -z "${basicAuthUserName}" ]]; then
    basicAuthUserName="-"
  fi
  if [[ -z "${basicAuthPassword}" ]]; then
    basicAuthPassword="-"
  fi
  hostName="${vhostList[0]}"
  hostAliasList=( "${vhosts[@]:1}" )
  if [[ "${#hostAliasList[@]}" -gt 0 ]]; then
    serverAlias=$( IFS=$','; echo "${hostAliasList[*]}" )
  else
    serverAlias="-"
  fi
  if [[ "${#requireIpList[@]}" -gt 0 ]]; then
    requireIp=$( IFS=$','; echo "${requireIpList[*]}" )
  else
    requireIp="-"
  fi
  echo "Adding Apache configuration: ${host}"
  if [[ "${overwrite}" == 1 ]]; then
    "${apacheScript}" \
      -s "${serverType}" \
      -u "${sshUser}" \
      -t "${sshHost}" \
      -w "${webPath}" \
      -n "${host}" \
      -v "${hostName}" \
      -b "${serverAlias}" \
      -e "${apacheHttpPort}" \
      -d "${apacheSslPort}" \
      -r "${scope}" \
      -c "${code}" \
      -m "${sslTerminated}" \
      -f "${forceSsl}" \
      -a "${basicAuthUserName}" \
      -p "${basicAuthPassword}" \
      -q "${requireIp}" \
      -l "${sslCertFile}" \
      -k "${sslKeyFile}" \
      -o
  else
    "${apacheScript}" \
      -s "${serverType}" \
      -u "${sshUser}" \
      -t "${sshHost}" \
      -w "${webPath}" \
      -n "${host}" \
      -v "${hostName}" \
      -b "${serverAlias}" \
      -e "${apacheHttpPort}" \
      -d "${apacheSslPort}" \
      -r "${scope}" \
      -c "${code}" \
      -m "${sslTerminated}" \
      -f "${forceSsl}" \
      -a "${basicAuthUserName}" \
      -p "${basicAuthPassword}" \
      -q "${requireIp}" \
      -l "${sslCertFile}" \
      -k "${sslKeyFile}"
  fi
  sleep 5
done

#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -o  Overwrite existing files (Optional)

Example: ${scriptName} -o
EOF
}

trim()
{
  echo -n "$1" | xargs
}

overwrite=0

while getopts ho? option; do
  case ${option} in
    h) usage; exit 1;;
    o) overwrite=1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f ${currentPath}/../env.properties ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
  if [[ -n "${webServer}" ]]; then
    echo "--- Installing web server for server: ${server} ---"
    webServerType=$(ini-parse "${currentPath}/../env.properties" "yes" "${webServer}" "type")
    webServerScript="${currentPath}/web-server/${webServerType}.sh"
    if [[ ! -f "${webServerScript}" ]]; then
      echo "Missing web server type script: ${webServerScript}"
      exit 1
    fi
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    sshUser=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "user")
    sshHost=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "host")
    webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
    if [[ -z "${sshUser}" ]]; then
      sshUser="-"
    fi
    if [[ -z "${sshHost}" ]]; then
      sshHost="-"
    fi
    if [[ "${overwrite}" == 1 ]]; then
      "${webServerScript}" \
        -s "${serverType}" \
        -u "${sshUser}" \
        -t "${sshHost}" \
        -p "${webPath}" \
        -w "${webServer}" \
        -o
    else
      "${webServerScript}" \
        -s "${serverType}" \
        -u "${sshUser}" \
        -t "${sshHost}" \
        -p "${webPath}" \
        -w "${webServer}"
    fi
  fi
done

#nginxVersion=$(ini-parse "${currentPath}/../env.properties" "no" "project" "nginxVersion")
#nginxHttpPort=$(ini-parse "${currentPath}/../env.properties" "no" "project" "nginxHttpPort")
#nginxSslPort=$(ini-parse "${currentPath}/../env.properties" "no" "project" "nginxSslPort")
#varnishVersion=$(ini-parse "${currentPath}/../env.properties" "no" "project" "varnishVersion")
#varnishHost=$(ini-parse "${currentPath}/../env.properties" "no" "project" "varnishHost")
#varnishPort=$(ini-parse "${currentPath}/../env.properties" "no" "project" "varnishPort")
#varnishMaxMemory=$(ini-parse "${currentPath}/../env.properties" "no" "project" "varnishMaxMemory")

#if [[ -n "${varnishPort}" ]]; then
#  nginxScript="${currentPath}/nginx/${nginxVersion}/install.sh"
#  if [[ ! -f "${nginxScript}" ]]; then
#    echo "Missing Nginx script: ${nginxScript}"
#    exit 1
#  fi
#  varnishScript="${currentPath}/varnish/${varnishVersion}/install.sh"
#  if [[ ! -f "${varnishScript}" ]]; then
#    echo "Missing Varnish script: ${varnishScript}"
#    exit 1
#  fi
#  if [[ -z "${varnishMaxMemory}" ]]; then
#    echo "No Varnish max memory specified!"
#    exit 1
#  fi
#fi
#if [[ -n "${varnishPort}" ]]; then
#  if [[ -z "${nginxHttpPort}" ]]; then
#    echo "No Nginx HTTP port specified!"
#    exit 1
#  fi
#  if [[ -z "${nginxSslPort}" ]]; then
#    echo "No Nginx SSL port specified!"
#    exit 1
#  fi
#  if [[ -z "${varnishHost}" ]]; then
#    echo "No Varnish host specified!"
#    exit 1
#  fi
#  if [[ -z "${varnishPort}" ]]; then
#    echo "No Varnish port specified!"
#    exit 1
#  fi
#  varnishScript="${currentPath}/varnish/${varnishVersion}/install.sh"
#  echo "Adding Varnish configuration"
#  if [[ "${overwrite}" == 1 ]]; then
#    "${varnishScript}" -m "${varnishMaxMemory}" -o
#  else
#    "${varnishScript}" -m "${varnishMaxMemory}"
#  fi
#  nginxScript="${currentPath}/nginx/${nginxVersion}/install.sh"
#  for hostSection in "${hosts[@]}"; do
#    vhosts=( $(ini-parse "${currentPath}/../env.properties" "yes" "${hostSection}" "vhost") )
#    sslCertFile=$(ini-parse "${currentPath}/../env.properties" "no" "${hostSection}" "sslCertFile")
#    sslKeyFile=$(ini-parse "${currentPath}/../env.properties" "no" "${hostSection}" "sslKeyFile")
#    sslTerminated=$(ini-parse "${currentPath}/../env.properties" "no" "${hostSection}" "sslTerminated")
#    forceSsl=$(ini-parse "${currentPath}/../env.properties" "no" "${hostSection}" "forceSsl")
#    requireIpList=( $(ini-parse "${currentPath}/../env.properties" "no" "${hostSection}" "requireIp") )
#    basicAuthUserName=$(ini-parse "${currentPath}/../env.properties" "no" "${hostSection}" "basicAuthUserName")
#    basicAuthPassword=$(ini-parse "${currentPath}/../env.properties" "no" "${hostSection}" "basicAuthPassword")
#    if [[ -z "${sslCertFile}" ]]; then
#      sslCertFile="/etc/ssl/certs/ssl-cert-snakeoil.pem"
#    fi
#    if [[ -z "${sslKeyFile}" ]]; then
#      sslKeyFile="/etc/ssl/private/ssl-cert-snakeoil.key"
#    fi
#    if [[ -z "${sslTerminated}" ]]; then
#      nginxSslTerminated="no"
#    else
#      nginxSslTerminated="${sslTerminated}"
#    fi
#    if [[ "${nginxSslTerminated}" == 0 ]]; then
#      nginxSslTerminated=no
#    fi
#    if [[ "${nginxSslTerminated}" == 1 ]]; then
#      nginxSslTerminated=yes
#    fi
#    if [[ -z "${forceSsl}" ]]; then
#      forceSsl="yes"
#    fi
#    hostName="${vhosts[0]}"
#    hostAliasList=( "${vhosts[@]:1}" )
#    if [[ "${#requireIpList[@]}" -gt 0 ]]; then
#      requireIp=$( IFS=$','; echo "${requireIpList[*]}" )
#    else
#      requireIp="-"
#    fi
#    if [[ -z "${basicAuthUserName}" ]]; then
#      basicAuthUserName="-"
#    fi
#    if [[ -z "${basicAuthPassword}" ]]; then
#      basicAuthPassword="-"
#    fi
#    echo "Adding Nginx configuration: ${hostSection}"
#    if [[ "${overwrite}" == 1 ]]; then
#      "${nginxScript}" \
#        -v "${hostName}" \
#        -b "${serverAlias}" \
#        -r "${varnishHost}" \
#        -i "${varnishPort}" \
#        -t "${nginxSslTerminated}" \
#        -f "${forceSsl}" \
#        -u "${basicAuthUserName}" \
#        -p "${basicAuthPassword}" \
#        -q "${requireIp}" \
#        -c "${sslCertFile}" \
#        -k "${sslKeyFile}" \
#        -o
#    else
#      "${nginxScript}" \
#        -v "${hostName}" \
#        -b "${serverAlias}" \
#        -r "${varnishHost}" \
#        -i "${varnishPort}" \
#        -t "${nginxSslTerminated}" \
#        -f "${forceSsl}" \
#        -u "${basicAuthUserName}" \
#        -p "${basicAuthPassword}" \
#        -q "${requireIp}" \
#        -c "${sslCertFile}" \
#        -k "${sslKeyFile}"
#    fi
#    sleep 5
#  done
#fi

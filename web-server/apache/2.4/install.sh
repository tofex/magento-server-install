#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -s  Server type
  -u  SSH user (required when SSH as server type)
  -t  SSH host (required when SSH as server type)
  -n  Config name
  -v  Server name
  -b  Server Alias List, separated by comma
  -r  Magento run type, default: website
  -c  Magento run code, default: base
  -m  SSL terminated (yes/no), default: no
  -f  Force SSL (yes/no), default: yes
  -a  Basic auth user name
  -p  Basic auth password
  -q  Allow IPs without basic auth, separated by comma
  -l  SSL certificate file, default: /etc/ssl/certs/ssl-cert-snakeoil.pem
  -k  SSL key file, default: /etc/ssl/private/ssl-cert-snakeoil.key
  -o  Overwrite existing files (optional), default: no

Example: ${scriptName} -v project01.tofex.net -m production -r website -c base -t yes -f no
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
configName=
serverName=
serverAlias=
apacheHttpPort="80"
apacheSslPort="443"
varnishPort=
mageRunType="website"
mageRunCode="base"
sslTerminated="no"
forceSsl="yes"
basicAuthUserName="-"
basicAuthPassword="-"
requireIp=
sslCertFile="/etc/ssl/certs/ssl-cert-snakeoil.pem"
sslKeyFile="/etc/ssl/private/ssl-cert-snakeoil.key"
overwrite="no"

while getopts hs:u:t:w:n:v:b:e:d:i:r:c:m:f:a:p:q:l:k:o? option; do
  case ${option} in
    h) usage; exit 1;;
    s) serverType=$(trim "$OPTARG");;
    u) sshUser=$(trim "$OPTARG");;
    t) sshHost=$(trim "$OPTARG");;
    w) webPath=$(trim "$OPTARG");;
    n) configName=$(trim "$OPTARG");;
    v) serverName=$(trim "$OPTARG");;
    b) serverAlias=$(trim "$OPTARG");;
    e) apacheHttpPort=$(trim "$OPTARG");;
    d) apacheSslPort=$(trim "$OPTARG");;
    i) varnishPort=$(trim "$OPTARG");;
    r) mageRunType=$(trim "$OPTARG");;
    c) mageRunCode=$(trim "$OPTARG");;
    m) sslTerminated=$(trim "$OPTARG");;
    f) forceSsl=$(trim "$OPTARG");;
    a) basicAuthUserName=$(trim "$OPTARG");;
    p) basicAuthPassword=$(trim "$OPTARG");;
    q) requireIp=$(trim "$OPTARG");;
    l) sslCertFile=$(trim "$OPTARG");;
    k) sslKeyFile=$(trim "$OPTARG");;
    o) overwrite="yes";;
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

if [[ -z "${configName}" ]]; then
  echo "No config name specified!"
  exit 1
fi

if [[ -z "${serverName}" ]]; then
  echo "No server name specified!"
  exit 1
fi

if [[ -z "${serverAlias}" ]]; then
  serverAlias="-"
fi

if [[ -z "${apacheHttpPort}" ]]; then
  echo "No HTTP port specified!"
  exit 1
fi

if [[ -z "${apacheSslPort}" ]]; then
  echo "No SSL port specified!"
  exit 1
fi

if [[ -z "${varnishPort}" ]]; then
  varnishPort="-"
fi

if [[ -z "${mageRunType}" ]]; then
  echo "No mage run type specified!"
  exit 1
fi

if [[ -z "${mageRunCode}" ]]; then
  echo "No mage run code specified!"
  exit 1
fi

if [[ -z "${sslTerminated}" ]]; then
  echo "No SSL terminated specified!"
  exit 1
fi

if [[ -z "${forceSsl}" ]]; then
  echo "No force SSL specified!"
  exit 1
fi

if [[ -z "${requireIp}" ]]; then
  requireIp="-"
fi

if [[ -z "${sslCertFile}" ]]; then
  sslCertFile="-"
fi

if [[ -z "${sslKeyFile}" ]]; then
  sslKeyFile="-"
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f ${currentPath}/../../../../env.properties ]]; then
  echo "No environment specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "install" "magentoVersion")

if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

installScript="${currentPath}/magento${magentoVersion:0:1}.sh"
if [[ ! -f "${installScript}" ]]; then
  echo "Missing Apache install script: ${installScript}"
  exit 1
fi

echo "Adding Apache virtual host for Magento ${magentoVersion:0:1}"

magentoMode=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "install" "magentoMode")

if [[ -z "${magentoMode}" ]]; then
  echo "No mage mode specified!"
  exit 1
fi

if [[ -z "${webUser}" ]]; then
  webUser="$(whoami)"
fi
if [[ -z "${webGroup}" ]]; then
  webGroup="$(id -g -n)"
fi

if [[ "${serverType}" == "local" ]]; then
  "${installScript}" \
    -n "${configName}" \
    -v "${serverName}" \
    -b "${serverAlias}" \
    -m "${magentoMode}" \
    -r "${mageRunType}" \
    -c "${mageRunCode}" \
    -t "${sslTerminated}" \
    -f "${forceSsl}" \
    -u "${basicAuthUserName}" \
    -p "${basicAuthPassword}" \
    -q "${requireIp}" \
    -w "${webPath}" \
    -e "${webUser}" \
    -g "${webGroup}" \
    -a "${apacheHttpPort}" \
    -s "${apacheSslPort}" \
    -i "${varnishPort}" \
    -l "${sslCertFile}" \
    -k "${sslKeyFile}" \
    -o "${overwrite}"
else
  installScriptName=$(basename "${installScript}")
  scp -q "${installScript}" "${sshUser}@${sshHost}:/tmp/${installScriptName}"
  ssh "${sshUser}@${sshHost}" "/tmp/${installScriptName}" \
    -n "${configName}" \
    -v "${serverName}" \
    -b "${serverAlias}" \
    -m "${magentoMode}" \
    -r "${mageRunType}" \
    -c "${mageRunCode}" \
    -t "${sslTerminated}" \
    -f "${forceSsl}" \
    -u "${basicAuthUserName}" \
    -p "${basicAuthPassword}" \
    -q "${requireIp}" \
    -w "${webPath}" \
    -e "${webUser}" \
    -g "${webGroup}" \
    -a "${apacheHttpPort}" \
    -s "${apacheSslPort}" \
    -i "${varnishPort}" \
    -l "${sslCertFile}" \
    -k "${sslKeyFile}" \
    -o "${overwrite}"
fi

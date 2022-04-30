#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -b  Bind address, default: 127.0.0.1
  -i  Server Id, default: 1
  -c  Connections, default: 100
  -s  InnoDB buffer pool size in GB, default: 4

Example: ${scriptName} -m dev -a -u
EOF
}

trim()
{
  echo -n "$1" | xargs
}

bindAddress=""
serverId="1"
connections=
innodbBufferPoolSize=

while getopts hb:i:c:s:? option; do
  case ${option} in
    h) usage; exit 1;;
    b) bindAddress=$(trim "$OPTARG");;
    i) serverId=$(trim "$OPTARG");;
    c) connections=$(trim "$OPTARG");;
    s) innodbBufferPoolSize=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${bindAddress}" ]]; then
  bindAddress="127.0.0.1"
fi

if [[ -z "${connections}" ]]; then
  connections="100"
fi

if [[ -z "${innodbBufferPoolSize}" ]]; then
  innodbBufferPoolSize="4"
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f ${currentPath}/../../env.properties ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

database=
databaseHost=
for server in "${serverList[@]}"; do
  database=$(ini-parse "${currentPath}/../../env.properties" "no" "${server}" "database")
  if [[ -n "${database}" ]]; then
    serverType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "type")
    if [[ "${serverType}" == "local" ]]; then
      databaseHost="localhost"
    else
      databaseHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "host")
    fi
    break
  fi
done

if [[ -z "${databaseHost}" ]]; then
  echo "No database settings found"
  exit 1
fi

databaseType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${database}" "type")
databaseVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${database}" "version")

if [[ -z "${databaseType}" ]]; then
  echo "No database type specified!"
  exit 1
fi

if [[ -z "${databaseVersion}" ]]; then
  echo "No database version specified!"
  exit 1
fi

databaseScript="${currentPath}/${databaseType}/${databaseVersion}/config.sh"

if [[ ! -f "${databaseScript}" ]]; then
  echo "Missing Database script: ${databaseScript}"
  exit 1
fi

"${databaseScript}" -b "${bindAddress}" -i "${serverId}" -c "${connections}" -s "${innodbBufferPoolSize}"

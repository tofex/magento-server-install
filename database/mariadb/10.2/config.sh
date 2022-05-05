#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -b  Bind address
  -i  Server Id, default: 1
  -c  Connections, default: 100
  -s  InnoDB buffer pool size in GB, default: 4

Example: ${scriptName} -b 0.0.0.0 -i 1 -c 100 -s 4
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
  case "${option}" in
    h) usage; exit 1;;
    b) bindAddress=$(trim "$OPTARG");;
    i) serverId=$(trim "$OPTARG");;
    c) connections=$(trim "$OPTARG");;
    s) innodbBufferPoolSize=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${serverId}" ]]; then
  echo "No server id specified!"
  exit 1
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../../../../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

if [[ -z "${connections}" ]]; then
  connections="100"
fi

if [[ -z "${innodbBufferPoolSize}" ]]; then
  innodbBufferPoolSize="4"
fi

serverList=( $(ini-parse "${currentPath}/../../../../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  database=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${server}" "database")
  if [[ -n "${database}" ]]; then
    serverType=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${server}" "type")
    databasePort=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${database}" "port")
    if [[ "${serverType}" == "local" ]]; then
      echo "--- Installing database on local server: ${server} ---"
      if [[ -z "${bindAddress}" ]]; then
        bindAddress="127.0.0.1"
      fi
      "${currentPath}/config-local.sh" -b "${bindAddress}" -p "${databasePort}" -i "${serverId}" -c "${connections}" -s "${innodbBufferPoolSize}"
    else
      sshUser=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${server}" "user")
      sshHost=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${server}" "host")
      echo "--- Installing database on remote server: ${server} ---"
      if [[ -z "${bindAddress}" ]]; then
        bindAddress="${sshHost}"
      fi
      echo "Copying script to ${sshUser}@${sshHost}:/tmp/config-local.sh"
      scp -q "${currentPath}/config-local.sh" "${sshUser}@${sshHost}:/tmp/config-local.sh"
      ssh "${sshUser}@${sshHost}" /tmp/config-local.sh -b "${bindAddress}" -p "${databasePort}" -i "${serverId}" -c "${connections}" -s "${innodbBufferPoolSize}"
    fi
  fi
done

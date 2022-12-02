#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
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

Example: ${scriptName} -b 0.0.0.0 -c 200
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

"${currentPath}/../core/script/run.sh" "database:all" "${currentPath}/database/[databaseType]/[databaseVersion]/database.sh" \
  --bindAddress "${bindAddress}" \
  --serverId "${serverId}" \
  --connections "${connections}" \
  --innodbBufferPoolSize "${innodbBufferPoolSize}"

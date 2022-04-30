#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -t  Type of instance (cache, session, fpc)
  -m  Max memory in MB
  -s  Save the data on disk (yes/no), default: no
  -y  Allow sync (yes/no), default: no

Example: ${scriptName} -t cache -m 2048
EOF
}

trim()
{
  echo -n "$1" | xargs
}

type=
maxMemory=
save=
allowSync=

while getopts ht:m:s:y:? option; do
  case "${option}" in
    h) usage; exit 1;;
    t) type=$(trim "$OPTARG");;
    m) maxMemory=$(trim "$OPTARG");;
    s) save=$(trim "$OPTARG");;
    y) allowSync=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${type}" ]]; then
  echo "No type specified!"
  exit 1
fi

if [[ -z "${maxMemory}" ]]; then
  echo "No max memory specified!"
  exit 1
fi

if [[ -z "${save}" ]]; then
  save="no"
fi

if [[ -z "${allowSync}" ]]; then
  allowSync="no"
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

redisVersion=
for server in "${serverList[@]}"; do
  if [[ "${type}" == "cache" ]]; then
    redisCache=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "redisCache")
    if [[ -n "${redisCache}" ]]; then
      redisVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisCache}" "version")
    fi
  elif [[ "${type}" == "session" ]]; then
    redisSession=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "redisSession")
    if [[ -n "${redisSession}" ]]; then
      redisVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisSession}" "version")
    fi
  elif [[ "${type}" == "fpc" ]]; then
    redisFPC=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "redisFPC")
    if [[ -n "${redisFPC}" ]]; then
      redisVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisFPC}" "version")
    fi
  fi
done

if [[ -z "${redisVersion}" ]]; then
  echo "No Redis version specified!"
  exit 1
fi

redisScript="${currentPath}/${redisVersion}/${type}/config.sh"

if [[ ! -f "${redisScript}" ]]; then
  echo "Missing Redis script: ${redisScript}"
  exit 1
fi

"${redisScript}" \
  -m "${maxMemory}" \
  -s "${save}" \
  -y "${allowSync}"

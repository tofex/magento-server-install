#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Max memory in MB
  -s  Save the data on disk (yes/no), default: no
  -y  Allow sync (yes/no), default: no

Example: ${scriptName} -m 2048 -s no
EOF
}

trim()
{
  echo -n "$1" | xargs
}

randomString()
{
  local length
  length=${1}
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w "${1:-${length}}" | head -n 1
}

maxMemory=
save=
allowSync=

while getopts hm:s:y:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) maxMemory=$(trim "$OPTARG");;
    s) save=$(trim "$OPTARG");;
    y) allowSync=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

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

if [[ ! -f "${currentPath}/../../../../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

syncAlias=
if [[ "${allowSync}" == "no" ]]; then
  syncAlias=$(randomString 32)
fi

psyncAlias=
if [[ "${allowSync}" == "no" ]]; then
  psyncAlias=$(randomString 32)
fi

serverList=( $(ini-parse "${currentPath}/../../../../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  serverType=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${server}" "type")
  redisCache=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${server}" "redisCache")
  if [[ -n "${redisCache}" ]]; then
    redisCachePort=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${redisCache}" "port")
    if [[ -z "${redisCachePort}" ]]; then
      echo "No Redis cache port specified!"
      exit 1
    fi
    redisCachePassword=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${redisCache}" "password")
    if [[ -n "${redisCachePassword}" ]]; then
      shutdownCommand="\\\$CLIEXEC -p \\\$REDISPORT -a ${redisCachePassword} shutdown"
    else
      shutdownCommand="\\\$CLIEXEC -p \\\$REDISPORT shutdown"
    fi
    if [[ "${serverType}" == "local" ]]; then
      echo "--- Installing Redis cache configuration on local server: ${server} ---"
      "${currentPath}/config-local.sh" \
        -p "${redisCachePort}" \
        -m "${maxMemory}" \
        -s "${save}" \
        -a "${allowSync}" \
        -y "${syncAlias}" \
        -i "${psyncAlias}" \
        -c "${shutdownCommand}"
    else
      echo "--- Installing Redis cache configuration on remote server: ${server} ---"
    fi
  fi
done

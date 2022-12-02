#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
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

randomString()
{
  local length
  length=${1}
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w "${1:-${length}}" | head -n 1
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
  >&2 echo "No Redis type specified!"
  exit 1
fi

if [[ -z "${maxMemory}" ]]; then
  >&2 echo "No max memory specified!"
  exit 1
fi

if [[ -z "${save}" ]]; then
  save="no"
fi

if [[ -z "${allowSync}" ]]; then
  allowSync="no"
fi

syncAlias=
if [[ "${allowSync}" == "no" ]]; then
  syncAlias=$(randomString 32)
fi

psyncAlias=
if [[ "${allowSync}" == "no" ]]; then
  psyncAlias=$(randomString 32)
fi

if [[ "${type}" == "cache" ]]; then
  "${currentPath}/../core/script/run.sh" "redisCache:all" "${currentPath}/redis/[redisCacheVersion]/cache/redis.sh" \
    --maxMemory "${maxMemory}" \
    --save "${save}" \
    --allowSync "${allowSync}" \
    --syncAlias "${syncAlias}" \
    --psyncAlias "${psyncAlias}"
elif [[ "${type}" == "fpc" ]]; then
  "${currentPath}/../core/script/run.sh" "redisFPC:all" "${currentPath}/redis/[redisFPCVersion]/fpc/redis.sh" \
    --maxMemory "${maxMemory}" \
    --save "${save}" \
    --allowSync "${allowSync}" \
    --syncAlias "${syncAlias}" \
    --psyncAlias "${psyncAlias}"
elif [[ "${type}" == "session" ]]; then
  "${currentPath}/../core/script/run.sh" "redisSession:all" "${currentPath}/redis/[redisSessionVersion]/session/redis.sh" \
    --maxMemory "${maxMemory}" \
    --save "${save}" \
    --allowSync "${allowSync}" \
    --syncAlias "${syncAlias}" \
    --psyncAlias "${psyncAlias}"
else
  >&2 echo "Invalid type specified!"
  exit 1
fi

#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -s  System name, default: server
  -d  Use this database file, when not downloading from storage (optional)
  -e  Use this database mode for download (dev/test/live/none) if no file specified
  -m  Use this media file, when not downloading from storage (optional)
  -i  Use this media mode for download (dev/test/live/catalog/product/none) if no file specified
  -c  Solr cores to restore (local:remote,local2:remote2)
  -a  Access token to Google storage

Example: ${scriptName} -a 12345
EOF
}

trim()
{
  echo -n "$1" | xargs
}

system=
databaseFile=
databaseMode=
mediaFile=
mediaMode=
solrCores=
accessToken=

while getopts hs:d:e:m:i:c:a:? option; do
  case "${option}" in
    h) usage; exit 1;;
    s) system=$(trim "$OPTARG");;
    d) databaseFile=$(trim "$OPTARG");;
    e) databaseMode=$(trim "$OPTARG");;
    m) mediaFile=$(trim "$OPTARG");;
    i) mediaMode=$(trim "$OPTARG");;
    c) solrCores=$(trim "$OPTARG");;
    a) accessToken=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${system}" ]]; then
  system="system"
fi

if [[ -z "${databaseFile}" ]] && [[ "${system}" == "system" ]] && [[ "${databaseMode}" != "dev" ]] && [[ "${databaseMode}" != "test" ]] && [[ "${databaseMode}" != "live" ]] && [[ "${databaseMode}" != "none" ]]; then
  echo "Invalid database mode"
  echo ""
  usage
  exit 1
fi

if [[ -n "${databaseFile}" ]] && [[ ! -f "${databaseFile}" ]]; then
  echo "Required database file not found at: ${databaseFile}"
  exit 1
fi

if [[ -z "${mediaFile}" ]] && [[ "${system}" == "system" ]] && [[ "${mediaMode}" != "dev" ]] && [[ "${mediaMode}" != "test" ]] && [[ "${mediaMode}" != "live" ]] && [[ "${mediaMode}" != "catalog" ]] && [[ "${mediaMode}" != "product" ]] && [[ "${mediaMode}" != "none" ]]; then
  echo "Invalid media mode"
  echo ""
  usage
  exit 1
fi

if [[ -n "${mediaFile}" ]] && [[ ! -f "${mediaFile}" ]]; then
  echo "Required database file not found at: ${mediaFile}"
  exit 1
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

if [[ -z "${accessToken}" ]]; then
  if [[ -z "${databaseFile}" ]] || [[ -z "${mediaFile}" ]] || [[ -n "${solrCores}" ]]; then
    echo "Please specify access token to Google storage, followed by [ENTER]:"
    read -r accessToken
  fi
fi

if [[ -n "${databaseFile}" ]]; then
  ../mysql/restore.sh -s "${system}" -f "${databaseFile}"
  ../config/admin.sh
  ../config/mails.sh
  ../config/prefix.sh
  ../config/urls.sh
elif [[ -n "${databaseMode}" ]] && [[ "${databaseMode}" != "none" ]]; then
  ../mysql/restore.sh -s "${system}" -m "${databaseMode}" -d -r -a "${accessToken}"
  ../config/admin.sh
  ../config/mails.sh
  ../config/prefix.sh
  ../config/urls.sh
else
  echo "Not restoring database"
fi

if [[ -n "${mediaFile}" ]]; then
  ../media/restore.sh -s "${system}" -f "${mediaFile}"
elif [[ -n "${mediaMode}" ]] && [[ "${mediaMode}" != "none" ]]; then
  ../media/restore.sh -s "${system}" -m "${mediaMode}" -d -r -a "${accessToken}"
else
  echo "Not restoring media"
fi

if [[ -n "${solrCores}" ]]; then
  solrCoreList=( $(echo "${solrCores}" | tr "," "\n") )
  for solrCore in "${solrCoreList[@]}"; do
    coreName=$(echo "${solrCore}" | cut -d: -f1)
    remoteCoreName=$(echo "${solrCore}" | cut -d: -f2)
    coreId="solr_${coreName}"
    ../solr/restore.sh -d -a "${accessToken}" -c "${coreId}" -e "${remoteCoreName}"
  done
else
  echo "Not restoring Solr cores"
fi

../ops/cache-clean.sh
../ops/fpc-clean.sh
../ops/session-clean.sh

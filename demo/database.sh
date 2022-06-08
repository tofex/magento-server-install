#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Magento version
  -e  Magento edition
  -o  Database host, default: localhost
  -p  Database port, default: 3306
  -u  Name of the database user
  -s  Password of the database user
  -b  Name of the database to import into
  -i  Import script file name

Example: ${scriptName} -m 2.3.7 -e community -u magento2 -s magento2 -b magento2 -i /tmp/mysql-import.sh
EOF
}

trim()
{
  echo -n "$1" | xargs
}

versionCompare() {
  if [[ "$1" == "$2" ]]; then
    echo "0"
  elif [[ "$1" = $(echo -e "$1\n$2" | sort -V | head -n1) ]]; then
    echo "1"
  else
    echo "2"
  fi
}

magentoVersion=
magentoEdition=
databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=
importScript=

while getopts hm:e:d:r:c:o:p:u:s:b:t:v:i:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) magentoEdition=$(trim "$OPTARG");;
    d) ;;
    r) ;;
    c) ;;
    o) databaseHost=$(trim "$OPTARG");;
    p) databasePort=$(trim "$OPTARG");;
    u) databaseUser=$(trim "$OPTARG");;
    s) databasePassword=$(trim "$OPTARG");;
    b) databaseName=$(trim "$OPTARG");;
    t) ;;
    v) ;;
    i) importScript=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version to install demo data specified!"
  exit 1
fi

if [[ -z "${magentoEdition}" ]]; then
  echo "No Magento edition to install demo data specified!"
  exit 1
fi

if [[ -z "${databaseHost}" ]]; then
  databaseHost="localhost"
fi

if [[ -z "${databasePort}" ]]; then
  databasePort="3306"
fi

if [[ -z "${databaseUser}" ]]; then
  echo "No database user specified!"
  usage
  exit 1
fi

if [[ -z "${databasePassword}" ]]; then
  echo "No database password specified!"
  usage
  exit 1
fi

if [[ -z "${databaseName}" ]]; then
  echo "No database name specified!"
  usage
  exit 1
fi

if [[ -z "${importScript}" ]]; then
  echo "No import script to install demo data specified!"
  exit 1
fi

if [[ ${magentoVersion:0:1} == 1 ]]; then
  tmpDir=$(mktemp -d -t XXXXXXXXXXXXXXXX)
  echo "Created temp dir: ${tmpDir}"
  cd "${tmpDir}"

  if [[ "${magentoEdition}" == "community" ]]; then
    echo "Downloading sample data from: https://www.googleapis.com/download/storage/v1/b/tofex_vm_data/o/magento-sample-data-1.9.2.4.tar.gz?alt=media"
    curl -X GET -o magento-sample-data-1.9.2.4.tar.gz https://www.googleapis.com/download/storage/v1/b/tofex_vm_data/o/magento-sample-data-1.9.2.4.tar.gz?alt=media
    gunzip magento-sample-data-1.9.2.4.tar.gz | cat
    tar -xf magento-sample-data-1.9.2.4.tar

    echo "Importing sample data"
    "${importScript}" \
      -o "${databaseHost}" \
      -p "${databasePort}" \
      -u "${databaseUser}" \
      -s "${databasePassword}" \
      -b "${databaseName}" \
      -i magento-sample-data-1.9.2.4/magento_sample_data_for_1.9.2.4.sql
  else
    echo "Downloading sample data from: https://www.googleapis.com/download/storage/v1/b/tofex_vm_data/o/magento-sample-data-1.14.2.4.tar.gz?alt=media"
    curl -X GET -o magento-sample-data-1.14.2.4.tar.gz https://www.googleapis.com/download/storage/v1/b/tofex_vm_data/o/magento-sample-data-1.14.2.4.tar.gz?alt=media
    gunzip magento-sample-data-1.14.2.4.tar.gz | cat
    tar -xf magento-sample-data-1.14.2.4.tar

    echo "Importing sample data"
    "${importScript}" \
      -o "${databaseHost}" \
      -p "${databasePort}" \
      -u "${databaseUser}" \
      -s "${databasePassword}" \
      -b "${databaseName}" \
      -i magento-sample-data-1.14.2.4/magento_sample_data_for_1.14.2.4.sql
  fi

  echo "Deleting temp dir: ${tmpDir}"
  rm -rf "${tmpDir}"
else
  echo "No database import required for Magento ${magentoVersion}"
fi

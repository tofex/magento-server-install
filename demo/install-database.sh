#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help              Show this message
  --magentoVersion    Magento version
  --magentoEdition    Magento edition
  --databaseHost      Database host, default: localhost
  --databasePort      Database port, default: 3306
  --databaseUser      Name of the database user
  --databasePassword  Password of the database user
  --databaseName      Name of the database to import into
  --importScript      Import script file name

Example: ${scriptName} --magentoVersion 2.3.7 --magentoEdition community --databaseUser magento2 --databasePassword magento2 --databaseName magento2 --importScript /tmp/mysql-import.sh
EOF
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

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

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

if [[ $(versionCompare "${magentoVersion}" "2.0.0") == 1 ]]; then
  tmpDir=$(mktemp -d -t XXXXXXXXXXXXXXXX)
  echo "Created temp dir: ${tmpDir}"
  cd "${tmpDir}"

  if [[ "${magentoEdition}" == "community" ]]; then
    echo "Downloading sample data from: https://github.com/Vinai/compressed-magento-sample-data/raw/master/compressed-magento-sample-data-1.9.2.4.tgz"
    curl -X GET -L -o compressed-magento-sample-data-1.9.2.4.tgz https://github.com/Vinai/compressed-magento-sample-data/raw/master/compressed-magento-sample-data-1.9.2.4.tgz
    gunzip compressed-magento-sample-data-1.9.2.4.tgz | cat
    tar -xf compressed-magento-sample-data-1.9.2.4.tar

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
elif [[ $(versionCompare "${magentoVersion}" "19.1.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "19.1.0") == 2 ]]; then
  echo "Downloading sample data from: https://github.com/Vinai/compressed-magento-sample-data/raw/master/compressed-magento-sample-data-1.9.2.4.tgz"
  curl -X GET -L -o compressed-magento-sample-data-1.9.2.4.tgz https://github.com/Vinai/compressed-magento-sample-data/raw/master/compressed-magento-sample-data-1.9.2.4.tgz
  gunzip compressed-magento-sample-data-1.9.2.4.tgz | cat
  tar -xf compressed-magento-sample-data-1.9.2.4.tar

  echo "Importing sample data"
  "${importScript}" \
    -o "${databaseHost}" \
    -p "${databasePort}" \
    -u "${databaseUser}" \
    -s "${databasePassword}" \
    -b "${databaseName}" \
    -i magento-sample-data-1.9.2.4/magento_sample_data_for_1.9.2.4.sql

  echo "Deleting temp dir: ${tmpDir}"
  rm -rf "${tmpDir}"
else
  echo "No database import required for Magento ${magentoVersion}"
fi

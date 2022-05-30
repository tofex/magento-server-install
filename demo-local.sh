#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -w  Web path
  -v  Magento version
  -e  Magento edition
  -i  Import script file name
  -s  Share script file name

Example: ${scriptName} -w /var/www/magento/htdocs -v 2.3.7 -e community -i /tmp/mysql-import.sh -i /tmp/create-shared.sh
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

webPath=
magentoVersion=
magentoEdition=
importScript=
shareScript=

while getopts hw:v:e:i:s:? option; do
  case "${option}" in
    h) usage; exit 1;;
    w) webPath=$(trim "$OPTARG");;
    v) magentoVersion=$(trim "$OPTARG");;
    e) magentoEdition=$(trim "$OPTARG");;
    i) importScript=$(trim "$OPTARG");;
    s) shareScript=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${webPath}" ]]; then
  echo "No web path to download specified!"
  exit 1
fi

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version to download specified!"
  exit 1
fi

if [[ -z "${magentoEdition}" ]]; then
  echo "No Magento edition to download specified!"
  exit 1
fi

if [[ -z "${importScript}" ]]; then
  echo "No import script to download specified!"
  exit 1
fi

if [[ -z "${shareScript}" ]]; then
  echo "No share script to download specified!"
  exit 1
fi

tmpDir=$(mktemp -d -t XXXXXXXXXXXXXXXX)
echo "Created temp dir: ${tmpDir}"
cd "${tmpDir}"

if [[ ${magentoVersion:0:1} == 1 ]]; then
  if [[ -L "${webPath}/skin/frontend/rwd/default/images/media" ]]; then
    rm -f "${webPath}/skin/frontend/rwd/default/images/media"
  fi

  if [[ "${magentoEdition}" == "community" ]]; then
    echo "Downloading sample data from: https://www.googleapis.com/download/storage/v1/b/tofex_vm_data/o/magento-sample-data-1.9.2.4.tar.gz?alt=media"
    curl -X GET -o magento-sample-data-1.9.2.4.tar.gz https://www.googleapis.com/download/storage/v1/b/tofex_vm_data/o/magento-sample-data-1.9.2.4.tar.gz?alt=media
    gunzip magento-sample-data-1.9.2.4.tar.gz | cat
    tar -xf magento-sample-data-1.9.2.4.tar
    mkdir -p "${webPath}"
    shopt -s dotglob

    echo "Copying sample data"
    cp -afR magento-sample-data-1.9.2.4/media/* "${webPath}/media/"
    cp -afR magento-sample-data-1.9.2.4/skin/* "${webPath}/skin/"

    echo "Importing sample data"
    "${importScript}" -i magento-sample-data-1.9.2.4/magento_sample_data_for_1.9.2.4.sql && echo "Import successful"
  else
    echo "Downloading sample data from: https://www.googleapis.com/download/storage/v1/b/tofex_vm_data/o/magento-sample-data-1.14.2.4.tar.gz?alt=media"
    curl -X GET -o magento-sample-data-1.14.2.4.tar.gz https://www.googleapis.com/download/storage/v1/b/tofex_vm_data/o/magento-sample-data-1.14.2.4.tar.gz?alt=media
    gunzip magento-sample-data-1.14.2.4.tar.gz | cat
    tar -xf magento-sample-data-1.14.2.4.tar
    mkdir -p "${webPath}"
    shopt -s dotglob

    echo "Copying sample data"
    cp -afR magento-sample-data-1.14.2.4/media/* "${webPath}/media/"
    mkdir -p "${webPath}/privatesales/"
    cp -afR magento-sample-data-1.14.2.4/privatesales/* "${webPath}/privatesales/"
    cp -afR magento-sample-data-1.14.2.4/skin/* "${webPath}/skin/"

    echo "Importing sample data"
    "${importScript}" -i magento-sample-data-1.14.2.4/magento_sample_data_for_1.14.2.4.sql && echo "Import successful"
  fi

  "${shareScript}" -f skin/frontend/rwd/default/images/media -o
else
  magentoVersion=$(echo "${magentoVersion}" | sed 's/-p[0-9]*$//')

  echo "Downloading sample data from: https://github.com/magento/magento2-sample-data/archive/${magentoVersion}.zip"
  wget -nv "https://github.com/magento/magento2-sample-data/archive/${magentoVersion}.zip"
  unzip -q "${magentoVersion}.zip"
  mkdir -p "${webPath}/app/code/Magento/"
  mkdir -p "${webPath}/pub/media/"
  rm -rf "${webPath}/pub/media/catalog/product/"
  shopt -s dotglob

  echo "Copying sample data"
  cp -afR "magento2-sample-data-${magentoVersion}"/app/code/Magento/* "${webPath}/app/code/Magento/"
  cp -afR "magento2-sample-data-${magentoVersion}"/pub/media/* "${webPath}/pub/media/"

  echo "Cleaning up"
  "${shareScript}" -f app/code/Magento -o
fi

echo "Deleting temp dir: ${tmpDir}"
rm -rf "${tmpDir}"

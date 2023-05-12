#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help            Show this message
  --magentoVersion  Magento version
  --magentoEdition  Magento edition
  --webPath         Web path

Example: ${scriptName} --magentoVersion 2.3.7 --magentoEdition community --webPath /var/www/magento/htdocs
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
webPath=

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

if [[ -z "${webPath}" ]]; then
  echo "No web path to install demo data specified!"
  exit 1
fi

tmpDir=$(mktemp -d -t XXXXXXXXXXXXXXXX)
echo "Created temp dir: ${tmpDir}"
cd "${tmpDir}"

if [[ $(versionCompare "${magentoVersion}" "2.0.0") == 1 ]]; then
  if [[ -L "${webPath}/skin/frontend/rwd/default/images/media" ]]; then
    rm -f "${webPath}/skin/frontend/rwd/default/images/media"
  fi

  if [[ "${magentoEdition}" == "community" ]]; then
    echo "Downloading sample data from: https://github.com/Vinai/compressed-magento-sample-data/raw/master/compressed-magento-sample-data-1.9.2.4.tgz"
    curl -X GET -L -o compressed-magento-sample-data-1.9.2.4.tgz https://github.com/Vinai/compressed-magento-sample-data/raw/master/compressed-magento-sample-data-1.9.2.4.tgz
    gunzip compressed-magento-sample-data-1.9.2.4.tgz | cat
    tar -xf compressed-magento-sample-data-1.9.2.4.tar
    mkdir -p "${webPath}"
    shopt -s dotglob

    echo "Copying sample data"
    cp -afR magento-sample-data-1.9.2.4/media/* "${webPath}/media/"
    cp -afR magento-sample-data-1.9.2.4/skin/* "${webPath}/skin/"
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
  fi
elif [[ $(versionCompare "${magentoVersion}" "19.1.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "19.1.0") == 2 ]]; then
  echo "Downloading sample data from: https://github.com/Vinai/compressed-magento-sample-data/raw/master/compressed-magento-sample-data-1.9.2.4.tgz"
  curl -X GET -L -o compressed-magento-sample-data-1.9.2.4.tgz https://github.com/Vinai/compressed-magento-sample-data/raw/master/compressed-magento-sample-data-1.9.2.4.tgz
  gunzip compressed-magento-sample-data-1.9.2.4.tgz | cat
  tar -xf compressed-magento-sample-data-1.9.2.4.tar
  mkdir -p "${webPath}"
  shopt -s dotglob

  echo "Copying sample data"
  cp -afR magento-sample-data-1.9.2.4/media/* "${webPath}/media/"
  cp -afR magento-sample-data-1.9.2.4/skin/* "${webPath}/skin/"
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
fi

echo "Deleting temp dir: ${tmpDir}"
rm -rf "${tmpDir}"

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
  -w  Web path
  -s  Share script file name
  -a  shared file path, default: shared

Example: ${scriptName} -m 2.3.7 -e community -w /var/www/magento/htdocs -s /tmp/ops-create-shared-local.sh -a shared
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
webPath=
shareScript=
sharedPath=

while getopts hm:e:d:r:w:u:g:t:v:p:z:x:y:s:a:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) magentoEdition=$(trim "$OPTARG");;
    d) ;;
    r) ;;
    w) webPath=$(trim "$OPTARG");;
    u) ;;
    g) ;;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    s) shareScript=$(trim "$OPTARG");;
    a) sharedPath=$(trim "$OPTARG");;
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

if [[ -z "${webPath}" ]]; then
  echo "No web path to install demo data specified!"
  exit 1
fi

if [[ -z "${shareScript}" ]]; then
  echo "No share script to install demo data specified!"
  exit 1
fi

if [[ -z "${sharedPath}" ]]; then
  sharedPath="static"
fi

tmpDir=$(mktemp -d -t XXXXXXXXXXXXXXXX)
echo "Created temp dir: ${tmpDir}"
cd "${tmpDir}"

webRoot=$(dirname "${webPath}")

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

  "${shareScript}" \
    -w "${webPath}" \
    -s "${webRoot}/${sharedPath}" \
    -f skin/frontend/rwd/default/images/media \
    -o
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

  "${shareScript}" \
    -w "${webPath}" \
    -s "${webRoot}/${sharedPath}" \
    -f app/code/Magento \
    -o
fi

echo "Deleting temp dir: ${tmpDir}"
rm -rf "${tmpDir}"

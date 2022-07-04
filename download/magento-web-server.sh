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
  -r  Repositories
  -w  Web path
  -o  Overwrite

Example: ${scriptName} -m 2.3.7 -e community -r "composer|https://repo.magento.com|12345|67890"
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
repositories=
webPath=
overwrite=0

while getopts hm:e:d:r:c:n:w:u:g:t:v:p:z:x:y:o? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) magentoEdition=$(trim "$OPTARG");;
    d) ;;
    r) repositories=$(trim "$OPTARG");;
    c) ;;
    n) ;;
    w) webPath=$(trim "$OPTARG");;
    u) ;;
    g) ;;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    o) overwrite=1;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version to download specified!"
  exit 1
fi

if [[ -z "${magentoEdition}" ]]; then
  echo "No Magento edition to download specified!"
  exit 1
fi

if [[ -z "${repositories}" ]]; then
  echo "No repositories to download specified!"
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path to download specified!"
  exit 1
fi

echo "Download Magento: ${magentoVersion}:${magentoEdition} to path: ${webPath}"

if [[ $(versionCompare "${magentoVersion}" "2.4.2") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "2.4.2") == 2 ]]; then
  composerSupport=2
elif [[ $(versionCompare "${magentoVersion}" "2.3.7") == 1 ]]; then
  composerSupport=1
elif [[ $(versionCompare "${magentoVersion}" "2.4.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "2.4.0") == 2 ]]; then
  composerSupport=1
else
  composerSupport=2
fi
echo "Composer support: ${composerSupport}"

composerVersion=$(composer -V | awk '{print $3}')
echo "Composer version: ${composerVersion}"

if [[ "${composerSupport}" == 1 ]]; then
  if [[ $(versionCompare "${composerVersion}" "1.10.21") == 1 ]]; then
    echo "Upgrading to composer: 1.10.21"
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer --version 1.10.21
  fi
  if [[ $(versionCompare "${composerVersion}" "2.0.0") == 0 ]] || [[ $(versionCompare "${composerVersion}" "2.0.0") == 2 ]]; then
    echo "Downgrading to composer: 1.10.21"
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer --version 1.10.21
  fi
else
  if [[ $(versionCompare "${composerVersion}" "2.3.5") == 1 ]]; then
    echo "Upgrading to composer: 2.3.5"
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer --version 2.3.5
  fi
  composer config --global --no-plugins allow-plugins.laminas/laminas-dependency-plugin true
  composer config --global --no-plugins allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
  composer config --global --no-plugins allow-plugins.magento/composer-root-update-plugin true
  composer config --global --no-plugins allow-plugins.magento/inventory-composer-installer true
  composer config --global --no-plugins allow-plugins.magento/magento-composer-installer true
fi

if [[ "${overwrite}" == 1 ]]; then
  echo "Removing previous installation"
  rm -rf "${webPath}"
fi
mkdir -p "${webPath}"

echo "${repositories}"

repositoryList=( $(echo "${repositories}" | tr "," "\n") )

if [[ ${magentoVersion:0:1} == 1 ]]; then
  for repository in "${repositoryList[@]}"; do
    repositoryUrl=$(echo "${repository}" | cut -d"|" -f2)
    repositoryComposerUser=$(echo "${repository}" | cut -d"|" -f3)
    repositoryComposerPassword=$(echo "${repository}" | cut -d"|" -f4)
    repositoryHostName=$(echo "${repositoryUrl}" | awk -F[/:] '{print $4}')
    echo "Adding composer repository access to url: ${repositoryUrl}"
    composer config --no-interaction -g "http-basic.${repositoryHostName}" "${repositoryComposerUser}" "${repositoryComposerPassword}"
  done
  echo "Creating composer project"
  phpVersion=$(php -v | head -n 1 | cut -d " " -f 2 | cut -f1-2 -d".")
  if [[ "${phpVersion}" == "5.4" ]]; then
    jq ".repositories.tofex += {\"options\": {\"ssl\": {\"verify_peer\": false, \"allow_self_signed\": true}}}" ~/.composer/config.json | sponge ~/.composer/config.json
    composer create-project "magento/project-${magentoEdition}-edition=${magentoVersion}-patch" --no-interaction --prefer-dist "${webPath}"
  else
    composer create-project --repository-url=https://composer.tofex.de/ "magento/project-${magentoEdition}-edition=${magentoVersion}-patch" --no-interaction --prefer-dist "${webPath}"
  fi
  #find "${webPath}" -type d -exec chmod 700 {} \; && find "${webPath}" -type f -exec chmod 600 {} \;
  chmod o+w "${webPath}/var" "${webPath}/var/.htaccess" "${webPath}/app/etc"
  chmod 755 "${webPath}/mage"
  chmod -R o+w "${webPath}/media"
else
  for repository in "${repositoryList[@]}"; do
    repositoryUrl=$(echo "${repository}" | cut -d"|" -f2)
    repositoryComposerUser=$(echo "${repository}" | cut -d"|" -f3)
    repositoryComposerPassword=$(echo "${repository}" | cut -d"|" -f4)
    repositoryHostName=$(echo "${repositoryUrl}" | awk -F[/:] '{print $4}')
    echo "Adding composer repository access to url: ${repositoryUrl}"
    composer config --no-interaction -g "http-basic.${repositoryHostName}" "${repositoryComposerUser}" "${repositoryComposerPassword}"
  done
  echo "Creating composer project"
  composer create-project --repository-url=https://repo.magento.com/ "magento/project-${magentoEdition}-edition=${magentoVersion}" --no-interaction --prefer-dist "${webPath}"
  #find "${webPath}" -type d -exec chmod 700 {} \; && find "${webPath}" -type f -exec chmod 600 {} \;
  chmod o+w "${webPath}/var" "${webPath}/var/.htaccess" "${webPath}/app/etc"
  chmod 755 "${webPath}/bin/magento"
  chmod -R o+w "${webPath}/pub/media"
fi

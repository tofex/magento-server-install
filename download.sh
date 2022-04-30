#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -o  Overwrite existing files (Optional)

Example: ${scriptName} -o
EOF
}

trim()
{
  echo -n "$1" | xargs
}

overwrite=0

while getopts ho? option; do
  case "${option}" in
    h) usage; exit 1;;
    o) overwrite=1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

repositoryList=( $(ini-parse "${currentPath}/../env.properties" "yes" "install" "repositories") )
magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
magentoEdition=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoEdition")
magentoMode=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoMode")

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  exit 1
fi

if [[ -z "${magentoEdition}" ]]; then
  echo "No Magento edition specified!"
  exit 1
fi

if [[ -z "${magentoMode}" ]]; then
  echo "No Magento mode specified!"
  exit 1
fi

if [[ "${#repositoryList[@]}" -eq 0 ]]; then
  echo "No composer repositories specified!"
  exit 1
fi

downloaded=0

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      repositories=$( IFS=$','; echo "${repositoryList[*]}" )
      echo "--- Downloading on local server: ${server} ---"
      if [[ "${overwrite}" == 1 ]]; then
        echo "Removing previous installation"
        rm -rf "${webPath}"
      fi
      mkdir -p "${webPath}"
      if [[ ${magentoVersion:0:1} == 1 ]]; then
        for repository in "${repositories[@]}"; do
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
        "${currentPath}/../ops/create-shared.sh" -f media -o
        "${currentPath}/../ops/create-shared.sh" -f var -o
      else
        for repository in "${repositories[@]}"; do
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
        if [[ "${magentoMode}" == "production" ]]; then
          "${currentPath}/../ops/create-shared.sh" -f generated -o
          echo "!!! Generated code folder is setup as symlink. Do not compile without real deployment process. !!!"
        fi
        "${currentPath}/../ops/create-shared.sh" -f pub/media -o
        "${currentPath}/../ops/create-shared.sh" -f pub/static -o
        "${currentPath}/../ops/create-shared.sh" -f var -o
      fi
      downloaded=1
    fi
  fi
done

if [[ "${downloaded}" == 0 ]]; then
  echo "Found no webservers to download to"
  exit 1
fi

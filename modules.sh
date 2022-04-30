#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f ${currentPath}/../env.properties ]]; then
  echo "No environment specified!"
  exit 1
fi

servers=$(ini-parse "${currentPath}/../env.properties" "yes" "project" "servers")
if [[ -z "${servers}" ]]; then
  echo "No servers specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

IFS=',' read -r -a serverList <<< "${servers}"

for server in "${serverList[@]}"; do
  type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
  if [[ "${type}" == "local" ]]; then
    webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
    webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
    webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")
    echo "--- Preparing server: ${server} ---"
    currentUser=$(whoami)
    if [[ -z "${webUser}" ]]; then
      webUser="${currentUser}"
    fi
    currentGroup=$(id -g -n)
    if [[ -z "${webGroup}" ]]; then
      webGroup="${currentGroup}"
    fi
    cd "${webPath}"
    if [[ ${magentoVersion:0:1} == 1 ]]; then
      if [[ ! -f composer.json ]]; then
        if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
          sudo -H -u "${webUser}" bash -c "echo \"{}\" > composer.json"
        else
          echo "{}" > composer.json
        fi
      fi
      phpVersion=$(php -v | head -n 1 | cut -d " " -f 2 | cut -f1-2 -d".")
      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "jq '.extra[\"magento-root-dir\"] = \".\"' composer.json | sponge composer.json"
        sudo -H -u "${webUser}" bash -c "jq '.extra[\"magento-deploystrategy\"] = \"copy\"' composer.json | sponge composer.json"
        sudo -H -u "${webUser}" bash -c "jq '.extra[\"magento-deploystrategy-dev\"] = \"copy\"' composer.json | sponge composer.json"
        sudo -H -u "${webUser}" bash -c "jq '.extra[\"with-bootstrap-patch\"] = false' composer.json | sponge composer.json"
        sudo -H -u "${webUser}" bash -c "jq '.extra[\"skip-suggest-repositories\"] = true' composer.json | sponge composer.json"
        sudo -H -u "${webUser}" bash -c "jq '.extra[\"magento-force\"] = true' composer.json | sponge composer.json"
        sudo -H -u "${webUser}" bash -c "rm -rf vendor/magento-hackathon/magento-composer-installer/"
        if [[ "${phpVersion}" == "5.4" ]]; then
          sudo -H -u "${webUser}" bash -c "composer require --prefer-dist magento-hackathon/magento-composer-installer=\"^3.0.0\""
        else
          sudo -H -u "${webUser}" bash -c "composer require --prefer-dist magento-hackathon/magento-composer-installer=\"^3.1.0\""
        fi
      else
        jq '.extra["magento-root-dir"] = "."' composer.json | sponge composer.json
        jq '.extra["magento-deploystrategy"] = "copy"' composer.json | sponge composer.json
        jq '.extra["magento-deploystrategy-dev"] = "copy"' composer.json | sponge composer.json
        jq '.extra["with-bootstrap-patch"] = false' composer.json | sponge composer.json
        jq '.extra["skip-suggest-repositories"] = true' composer.json | sponge composer.json
        jq '.extra["magento-force"] = true' composer.json | sponge composer.json
        rm -rf vendor/magento-hackathon/magento-composer-installer/
        if [[ "${phpVersion}" == "5.4" ]]; then
          composer require --prefer-dist magento-hackathon/magento-composer-installer="^3.0.0"
        else
          composer require --prefer-dist magento-hackathon/magento-composer-installer="^3.1.0"
        fi
      fi
    fi
  fi
done

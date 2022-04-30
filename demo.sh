#!/bin/bash -e

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

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

magentoEdition=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoEdition")
if [[ -z "${magentoEdition}" ]]; then
  echo "No magento edition specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      echo "--- Installing Magento demo data on local server: ${server} ---"
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
          "${currentPath}/../mysql/import.sh" -i magento-sample-data-1.9.2.4/magento_sample_data_for_1.9.2.4.sql && echo "Import successful"
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
          "${currentPath}/../mysql/import.sh" -i magento-sample-data-1.14.2.4/magento_sample_data_for_1.14.2.4.sql && echo "Import successful"
        fi
        "${currentPath}/../ops/create-shared.sh" -f skin/frontend/rwd/default/images/media -o
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
        "${currentPath}/../ops/create-shared.sh" -f app/code/Magento -o
      fi
      echo "Deleting temp dir: ${tmpDir}"
      rm -rf "${tmpDir}"
    fi
  fi
done

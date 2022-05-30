#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -e  Cloudflare auth e-mail
  -k  Cloudflare auth key

Example: ${scriptName} -e kontakt@project01.net -k 1245678901234567890
EOF
}

trim()
{
  echo -n "$1" | xargs
}

cloudflareAuthEmail=
cloudflareAuthKey=

while getopts he:k:? option; do
  case "${option}" in
    h) usage; exit 1;;
    e) cloudflareAuthEmail=$(trim "$OPTARG");;
    k) cloudflareAuthKey=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${cloudflareAuthEmail}" ]]; then
  echo "No Cloudflare auth email specified!"
  exit 1
fi

if [[ -z "${cloudflareAuthKey}" ]]; then
  echo "No Cloudflare auth key found!"
  exit 1
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

echo "Creating script to determine external IP at: /tmp/cloudflare.sh"
cat <<EOF | tee "/tmp/cloudflare.sh" > /dev/null
externalIp=\$(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip | cat)
if [[ -z "\${externalIp}" ]]; then
  externalIp=\$(curl -s https://ipinfo.io/ip | cat)
fi
echo "\${externalIp}"
EOF
chmod +x /tmp/cloudflare.sh

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    echo "--- Adding Cloudflare configuration to server: ${server} ---"
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")

    if [[ "${type}" == "local" ]]; then
      echo "Getting external IP of local server: ${server}"
      externalIp=$(/tmp/cloudflare.sh)
    else
      sshUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "user")
      sshHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      if [[ -z "${sshUser}" ]]; then
        echo "No SSL user specified!"
        exit 1
      fi
      if [[ -z "${sshHost}" ]]; then
        echo "No SSL host specified!"
        exit 1
      fi
      echo "Getting external IP of remote server: ${server}"

      echo "Getting server fingerprint"
      ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts

      echo "Copying script to ${sshUser}@${sshHost}:/tmp/cloudflare.sh"
      scp -q "/tmp/cloudflare.sh" "${sshUser}@${sshHost}:/tmp/cloudflare.sh"
      externalIp=$(ssh "${sshUser}@${sshHost}" "/tmp/cloudflare.sh")
      ssh "${sshUser}@${sshHost}" "rm -rf /tmp/cloudflare.sh"

      echo "Removing script from: ${sshUser}@${sshHost}:/tmp/cloudflare.sh"
      ssh "${sshUser}@${sshHost}" "rm -rf /tmp/cloudflare.sh"
    fi

    if [[ -z "${externalIp}" ]]; then
      echo "Could not determine external IP"
      exit 1
    fi
    echo "External IP: ${externalIp}"

    hostList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "host") )
    if [[ "${#hostList[@]}" -eq 0 ]]; then
      echo "No hosts specified!"
      exit 1
    fi

    for host in "${hostList[@]}"; do
      vhostList=( $(ini-parse "${currentPath}/../env.properties" "yes" "${host}" "vhost") )

      for vhost in "${vhostList[@]}"; do
        cloudflareZone=$(echo "${vhost}" | tr '.' $'\n' | tac | paste -s -d '.' | awk -F"." '{print $2"."$1}')
        projectName=$(echo "${vhost}" | sed -E "s/\.${cloudflareZone}//")

        echo "Getting Cloudflare zone identifier for: ${cloudflareZone}"
        cloudflareZoneIdentifier=$(\
          curl -s -X GET "https://api.cloudflare.com/client/v4/zones" \
          -H "X-Auth-Email: ${cloudflareAuthEmail}" \
          -H "X-Auth-Key: ${cloudflareAuthKey}" \
          -H "Content-Type: application/json" | jq ".result[] | select(.name == \"${cloudflareZone}\") | .id" | tr -d '"')

        if [[ -z "${cloudflareZoneIdentifier}" ]]; then
          echo "Cloudflare zone not found!"
          exit 1
        fi
        echo "Cloudflare zone identifier: ${cloudflareZoneIdentifier}"

        echo "Getting Cloudflare zone id for: ${projectName}"
        cloudflareId=$(\
         curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${cloudflareZoneIdentifier}/dns_records?name=${vhost}" \
          -H "X-Auth-Email: ${cloudflareAuthEmail}" \
          -H "X-Auth-Key: ${cloudflareAuthKey}" \
          -H "Content-Type: application/json" | jq ".result[] | .id" | tr -d '"')

        if [[ -n "${cloudflareId}" ]]; then
          echo "Updating cloudflare for: ${projectName} using id: ${cloudflareId}"
          curl -X PUT "https://api.cloudflare.com/client/v4/zones/${cloudflareZoneIdentifier}/dns_records/${cloudflareId}" \
            -H "X-Auth-Email: ${cloudflareAuthEmail}" \
            -H "X-Auth-Key: ${cloudflareAuthKey}" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"${projectName}\",\"content\":\"${externalIp}\",\"ttl\":1,\"proxied\":true}" | jq .
        else
          echo "Adding Cloudflare record for: ${projectName}"
          curl -X POST "https://api.cloudflare.com/client/v4/zones/${cloudflareZoneIdentifier}/dns_records" \
            -H "X-Auth-Email: ${cloudflareAuthEmail}" \
            -H "X-Auth-Key: ${cloudflareAuthKey}" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"${projectName}\",\"content\":\"${externalIp}\",\"ttl\":1,\"proxied\":true}" | jq .
        fi
      done
    done
  fi
done

echo "Removing script to determine external IP at: /tmp/cloudflare.sh"
rm -rf /tmp/cloudflare.sh

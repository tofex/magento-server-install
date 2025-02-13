#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help               Show this message
  --webPath            Web path
  --webUser            Web user, default: www-data
  --webGroup           Web group, default: www-data
  --httpPort           Apache HTTP port, default: 80
  --sslPort            Apache SSL port, default: 443
  --proxyHost          Proxy host
  --proxyPort          Proxy port
  --documentRootIsPub  Flag if pub folder is root directory (yes/no), default: yes
  --hostName           Host name
  --hostServerName     Server name
  --serverAlias        Server Alias List, separated by comma
  --scope              Magento run scope, default: default
  --code               Magento run code, default: default
  --sslCertFile        SSL certificate file, default: /etc/ssl/certs/ssl-cert-snakeoil.pem
  --sslKeyFile         SSL key file, default: /etc/ssl/private/ssl-cert-snakeoil.key
  --sslTerminated      SSL terminated (yes/no), default: no
  --forceSsl           Force SSL (yes/no), default: yes
  --requireIp          Allow IPs without basic auth, separated by comma
  --allowUrl           Allow Url without basic auth, separated by comma
  --basicAuthUserName  Basic auth user name
  --magentoVersion     Magento version
  --magentoMode        Magento mode (production or developer), default: production
  --overwrite          Overwrite existing files (optional), default: no

Example: ${scriptName} --webPath /var/www/magento/htdocs --hostName dev_magento2_de --hostServerName dev.magento2.de
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

webPath=
webUser=
webGroup=
httpPort=
sslPort=
proxyHost=
proxyPort=
documentRootIsPub=
hostName=
hostServerName=
serverAlias=
scope=
code=
sslCertFile=
sslKeyFile=
sslTerminated=
forceSsl=
requireIp=
allowUrl=
basicAuthUserName=
magentoVersion=
magentoMode=
overwrite=

if [[ -f "${currentPath}/../../../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  usage
  exit 1
fi

if [[ -z "${webUser}" ]]; then
  webUser="www-data"
fi

if [[ -z "${webGroup}" ]]; then
  webGroup="www-data"
fi

if [[ -z "${httpPort}" ]]; then
  httpPort=80
fi

if [[ -z "${sslPort}" ]]; then
  sslPort=443
fi

if [[ "${proxyHost}" == "-" ]]; then
  proxyHost=
fi

if [[ "${proxyPort}" == "-" ]]; then
  proxyPort=
fi

if [[ -z "${documentRootIsPub}" ]]; then
  documentRootIsPub="yes"
fi

if [[ -z "${hostName}" ]]; then
  echo "No host name specified!"
  usage
  exit 1
fi

if [[ -z "${hostServerName}" ]]; then
  echo "No host server name specified!"
  usage
  exit 1
fi

if [[ "${serverAlias}" == "-" ]]; then
  serverAlias=
fi

if [[ -z "${scope}" ]]; then
  scope="default"
fi

if [[ -z "${code}" ]]; then
  code="default"
fi

if [[ -z "${sslCertFile}" ]] || [[ "${sslCertFile}" == "-" ]]; then
  sslCertFile="/etc/ssl/certs/ssl-cert-snakeoil.pem"
fi

if [[ -z "${sslKeyFile}" ]] || [[ "${sslKeyFile}" == "-" ]]; then
  sslKeyFile="/etc/ssl/private/ssl-cert-snakeoil.key"
fi

if [[ -z "${sslTerminated}" ]]; then
  sslTerminated="no"
fi

if [[ -z "${forceSsl}" ]]; then
  forceSsl="yes"
fi

if [[ "${requireIp}" == "-" ]]; then
  requireIp=
fi

if [[ "${allowUrl}" == "-" ]]; then
  allowUrl=
fi

if [[ -z "${magentoMode}" ]]; then
  magentoMode="production"
fi

if [[ -z "${overwrite}" ]]; then
  overwrite="no"
fi

webRoot=$(dirname "${webPath}")

if [[ "${overwrite}" == "no" ]]; then
  if [[ -f "/etc/apache2/sites-available/${hostName}.conf" ]]; then
    echo "Configuration \"/etc/apache2/sites-available/${hostName}.conf\" already exists"
    exit 1
  fi
else
  if [[ -f "/etc/apache2/sites-available/${hostName}.conf" ]]; then
    echo "Copying configuration from \"/etc/apache2/sites-available/${hostName}.conf\" to \"/etc/apache2/sites-available/${hostName}.conf.old\""
    sudo cp "/etc/apache2/sites-available/${hostName}.conf" "/etc/apache2/sites-available/${hostName}.conf.old"
  fi
fi

if [[ $(versionCompare "${magentoVersion}" "2.2.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "2.2.0") == 2 ]]; then
  if [[ "${documentRootIsPub}" == "yes" ]]; then
    documentRoot="${webPath}/pub"
  else
    documentRoot="${webPath}"
  fi
else
  documentRoot="${webPath}"
fi

echo "Creating configuration at: /etc/apache2/sites-available/${hostName}.conf"

if [[ "${forceSsl}" == "yes" ]] && [[ "${sslTerminated}" == "no" ]]; then
  echo "Adding HTTP configuration for port: ${httpPort} and server name: ${hostServerName}"
  cat <<EOF | sudo tee "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
<VirtualHost *:${httpPort}>
  ServerName ${hostServerName}
EOF
  if [[ -n "${serverAlias}" ]]; then
    serverAliasList=( $(echo "${serverAlias}" | tr "," "\n") )
    for nextServerAlias in "${serverAliasList[@]}"; do
      echo "Adding HTTP server alias: ${nextServerAlias}"
      nextServerAliasList=( $(echo "${nextServerAlias}" | tr ":" "\n") )
      cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  ServerAlias ${nextServerAliasList[0]}
EOF
    done
  fi
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  ServerAdmin webmaster@localhost
  DocumentRoot ${documentRoot}/
  Redirect / https://${hostServerName}/
</VirtualHost>
EOF
else
  cat <<EOF | sudo tee "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
<VirtualHost *:${httpPort}>
  ServerName ${hostServerName}
EOF
  if [[ -n "${serverAlias}" ]]; then
    serverAliasList=( $(echo "${serverAlias}" | tr "," "\n") )
    for nextServerAlias in "${serverAliasList[@]}"; do
      echo "Adding HTTP server alias: ${nextServerAlias}"
      nextServerAliasList=( $(echo "${nextServerAlias}" | tr ":" "\n") )
      cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  ServerAlias ${nextServerAliasList[0]}
EOF
    done
  fi
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  ServerAdmin webmaster@localhost
  DocumentRoot ${documentRoot}/
  <Directory ${documentRoot}/>
EOF

  if [[ -n "${basicAuthUserName}" ]] && [[ "${basicAuthUserName}" != "-" ]]; then
    echo "Adding basic auth authorization with name: ${hostName}"
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    AuthType Basic
    AuthName "${hostName}"
    AuthUserFile "${webRoot}/${hostName}.htpasswd"
    Require valid-user
    Require ip 80.153.113.235
    Require ip 2003:a:771:7a00::/64
EOF
    if [[ -n "${requireIp}" ]]; then
      requireIpList=( $(echo "${requireIp}" | tr "," "\n") )
      for nextRequireIp in "${requireIpList[@]}"; do
        echo "Adding basic auth exception for remote IP: ${nextRequireIp}"
        cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    Require ip ${nextRequireIp}
EOF
      done
    fi
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    SetEnvIF X-Forwarded-For "80.153.113.235" AllowIP
    SetEnvIF X-Forwarded-For "2003:a:771:7a00:.*" AllowIP
EOF
    if [[ -n "${requireIp}" ]]; then
      requireIpList=( $(echo "${requireIp}" | tr "," "\n") )
      for nextRequireIp in "${requireIpList[@]}"; do
        echo "Adding basic auth exception for forwarded IP: ${nextRequireIp}"
        cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    SetEnvIF X-Forwarded-For "${nextRequireIp}" AllowIP
EOF
      done
    fi
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    Allow from env=AllowIP
    Allow from env=REDIRECT_AllowIP
EOF
    if [[ -n "${allowUrl}" ]]; then
      allowUrlList=( $(echo "${allowUrl}" | tr "," "\n") )
      for nextAllowUrl in "${allowUrlList[@]}"; do
        echo "Adding basic auth exception for url: ${nextAllowUrl}"
        cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    SetEnvIf Request_URI ${nextAllowUrl} AllowUrl
EOF
      done
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    Allow from env=AllowUrl
    Allow from env=REDIRECT_AllowUrl
EOF
    fi
  fi

  if [[ -n "${serverAlias}" ]]; then
    serverAliasList=( $(echo "${serverAlias}" | tr "," "\n") )
    for nextServerAlias in "${serverAliasList[@]}"; do
      nextServerAliasList=( $(echo "${nextServerAlias}" | tr ":" "\n") )
      if [[ "${nextServerAliasList[1]}" == "fake" ]]; then
        echo "Adding SSL server alias fake: ${nextServerAlias}"
        cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    SetEnvIF HOST "${nextServerAliasList[0]}" X-Main-Host="${hostServerName}"
EOF
      fi
    done
  fi

  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    Order Allow,Deny
    Satisfy any
    Options FollowSymLinks
    AllowOverride All
  </Directory>
EOF

  if [[ "${sslTerminated}" == "yes" ]] && [[ -z "${proxyHost}" ]] && [[ -z "${proxyPort}" ]]; then
    echo "Adding SSL rewrite for HTTP access"
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  RewriteEngine On
  RewriteCond %{HTTP:X-Forwarded-Proto} =http
  RewriteRule .* https://%{HTTP:Host}%{REQUEST_URI} [L,R=permanent]
EOF
  fi

  if [[ "${sslTerminated}" == "yes" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  SetEnv HTTPS on
EOF
  fi

  echo "Setting Magento entry with mode: ${magentoMode}, scope: ${scope} and code: ${code}"
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  SetEnv MAGE_MODE "${magentoMode}"
EOF
  if [[ "${scope}" != "default" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  SetEnv MAGE_RUN_TYPE "${scope}"
EOF
  fi
  if [[ "${code}" != "default" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  SetEnv MAGE_RUN_CODE "${code}"
EOF
  fi
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  LogLevel warn
  ErrorLog ${webRoot}/log/${hostName}-apache-http-error.log
  CustomLog ${webRoot}/log/${hostName}-apache-http-access.log custom
</VirtualHost>
EOF
fi

if [[ "${sslTerminated}" == "no" ]]; then
  if [[ -z "${sslCertFile}" ]]; then
    echo "No SSL certificate file specified!"
    exit 1
  fi

  if [[ ! -f "${sslCertFile}" ]]; then
    echo "Invalid SSL certificate file specified: ${sslCertFile}"
    exit 1
  fi

  if [[ -z "${sslKeyFile}" ]]; then
    echo "No SSL key file specified!"
    exit 1
  fi

  if sudo test ! -f "${sslKeyFile}"; then
    echo "Invalid SSL key file specified: ${sslKeyFile}"
    exit 1
  fi

  echo "Creating configuration at: /etc/apache2/sites-available/000-default.conf"
  cat <<EOF | sudo tee /etc/apache2/sites-available/000-default.conf > /dev/null
<VirtualHost *:${httpPort}>
  ServerAdmin webmaster@localhost.local
  DocumentRoot /var/www/html
  <Directory />
    Options FollowSymLinks
    AllowOverride None
  </Directory>
  <Directory /var/www/html/>
    Options Indexes FollowSymLinks MultiViews
    AllowOverride None
    Order allow,deny
    Allow from all
  </Directory>
  ErrorLog \${APACHE_LOG_DIR}/default-http-error.log
  LogLevel warn
  CustomLog \${APACHE_LOG_DIR}/default-http-access.log combined
</VirtualHost>
<IfModule mod_ssl.c>
  SSLCertificateFile ${sslCertFile}
  SSLCertificateKeyFile ${sslKeyFile}
  BrowserMatch \"MSIE [2-6]\" nokeepalive ssl-unclean-shutdown downgrade-1.0 force-response-1.0
  BrowserMatch \"MSIE [17-9]\" ssl-unclean-shutdown
  <FilesMatch \"\.(cgi|shtml|phtml|php)\$\">
    SSLOptions +StdEnvVars
  </FilesMatch>
  <VirtualHost *:${sslPort}>
    SSLEngine on
    ServerAdmin webmaster@localhost.local
    DocumentRoot /var/www/html
    <Directory />
      Options FollowSymLinks
      AllowOverride None
    </Directory>
    <Directory /var/www/html/>
      Options Indexes FollowSymLinks MultiViews
      AllowOverride None
      Order allow,deny
      Allow from all
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/default-ssl-error.log
    LogLevel warn
    CustomLog \${APACHE_LOG_DIR}/default-ssl-access.log combined
  </VirtualHost>
</IfModule>
EOF

  echo "Adding SSL configuration with port: ${sslPort} and server name: ${hostServerName}"
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
<IfModule mod_ssl.c>
  <VirtualHost *:${sslPort}>
    SSLEngine on
    SSLCertificateFile ${sslCertFile}
    SSLCertificateKeyFile ${sslKeyFile}
    ServerName ${hostServerName}
EOF
  if [[ -n "${serverAlias}" ]]; then
    serverAliasList=( $(echo "${serverAlias}" | tr "," "\n") )
    for nextServerAlias in "${serverAliasList[@]}"; do
      echo "Adding SSL server alias: ${nextServerAlias}"
      nextServerAliasList=( $(echo "${nextServerAlias}" | tr ":" "\n") )
      cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    ServerAlias ${nextServerAliasList[0]}
EOF
    done
  fi
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    ServerAdmin webmaster@localhost
    DocumentRoot ${documentRoot}/
    <Directory ${documentRoot}/>
EOF

  if [[ -n "${basicAuthUserName}" ]] && [[ "${basicAuthUserName}" != "-" ]]; then
    echo "Adding basic auth authorization with name: ${hostName}"
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
      AuthType Basic
      AuthName "${hostName}"
      AuthUserFile "${webRoot}/${hostName}.htpasswd"
      Require valid-user
      Require ip 80.153.113.235
      Require ip 2003:a:771:7a00::/64
EOF
    if [[ -n "${requireIp}" ]]; then
      requireIpList=( $(echo "${requireIp}" | tr "," "\n") )
      for nextRequireIp in "${requireIpList[@]}"; do
        echo "Adding basic auth exception for remote IP: ${nextRequireIp}"
        cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
      Require ip ${nextRequireIp}
EOF
      done
    fi
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
      SetEnvIF X-Forwarded-For "80.153.113.235" AllowIP
      SetEnvIF X-Forwarded-For "2003:a:771:7a00:.*" AllowIP
EOF
    if [[ -n "${requireIp}" ]]; then
      requireIpList=( $(echo "${requireIp}" | tr "," "\n") )
      for nextRequireIp in "${requireIpList[@]}"; do
        echo "Adding basic auth exception for forwarded IP: ${nextRequireIp}"
        cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
      SetEnvIF X-Forwarded-For "${nextRequireIp}" AllowIP
EOF
      done
    fi
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
      Allow from env=AllowIP
      Allow from env=REDIRECT_AllowIP
EOF
    if [[ -n "${allowUrl}" ]]; then
      allowUrlList=( $(echo "${allowUrl}" | tr "," "\n") )
      for nextAllowUrl in "${allowUrlList[@]}"; do
        echo "Adding basic auth exception for url: ${nextAllowUrl}"
        cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
      SetEnvIf Request_URI ${nextAllowUrl} AllowUrl
EOF
      done
      cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
      Allow from env=AllowUrl
      Allow from env=REDIRECT_AllowUrl
EOF
    fi
  fi

  if [[ -n "${serverAlias}" ]]; then
    serverAliasList=( $(echo "${serverAlias}" | tr "," "\n") )
    for nextServerAlias in "${serverAliasList[@]}"; do
      nextServerAliasList=( $(echo "${nextServerAlias}" | tr ":" "\n") )
      if [[ "${nextServerAliasList[1]}" == "fake" ]]; then
        echo "Adding SSL server alias fake: ${nextServerAlias}"
        cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
      SetEnvIF HOST "${nextServerAliasList[0]}" X-Main-Host="${hostServerName}"
EOF
      fi
    done
  fi

  echo "Setting Magento entry with mode: ${magentoMode}, scope: ${scope} and code: ${code}"
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
      Order Allow,Deny
      Satisfy any
      Options FollowSymLinks
      AllowOverride All
    </Directory>
    SetEnv MAGE_MODE "${magentoMode}"
EOF
  if [[ "${scope}" != "default" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    SetEnv MAGE_RUN_TYPE "${scope}"
EOF
  fi
  if [[ "${code}" != "default" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    SetEnv MAGE_RUN_CODE "${code}"
EOF
  fi
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    LogLevel warn
    ErrorLog ${webRoot}/log/${hostName}-apache-ssl-error.log
    CustomLog ${webRoot}/log/${hostName}-apache-ssl-access.log custom
  </VirtualHost>
</IfModule>
EOF
fi

echo "Enabling configuration at: /etc/apache2/sites-enabled/${hostName}.conf"
test ! -f "/etc/apache2/sites-enabled/${hostName}.conf" && sudo a2ensite "${hostName}.conf"

if [[ -f /.dockerenv ]]; then
  echo "Reloading Apache"
  sudo service apache2 reload
  sleep 5
else
  echo "Restarting Apache"
  sudo service apache2 restart
  sleep 5
fi

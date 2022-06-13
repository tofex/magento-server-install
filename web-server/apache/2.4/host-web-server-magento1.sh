#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -w  Web path
  -u  Web user, default: www-data
  -g  Web group, default: www-data
  -p  Apache HTTP port, default: 80
  -z  Apache SSL port, default: 443
  -x  Proxy host
  -y  Proxy port
  -n  Host name
  -o  Server name
  -a  Server Alias List, separated by comma
  -e  Magento run scope, default: default
  -c  Magento run code, default: default
  -l  SSL certificate file, default: /etc/ssl/certs/ssl-cert-snakeoil.pem
  -k  SSL key file, default: /etc/ssl/private/ssl-cert-snakeoil.key
  -r  SSL terminated (yes/no), default: no
  -f  Force SSL (yes/no), default: yes
  -i  Allow IPs without basic auth, separated by comma
  -j  Allow Url without basic auth, separated by comma
  -b  Basic auth user name
  -d  Magento mode (production or developer), default: production
  -j  Overwrite existing files (optional), default: no

Example: ${scriptName} -w /var/www/magento/htdocs -n dev_magento2_de -o dev.magento2.de
EOF
}

trim()
{
  echo -n "$1" | xargs
}

webPath=
webUser=
webGroup=
httpPort=
sslPort=
proxyHost=
proxyPort=
hostName=
serverName=
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
magentoMode=
overwrite=

while getopts hw:u:g:t:v:p:z:x:y:n:o:a:e:c:l:k:r:f:i:j:b:s:m:d:q:? option; do
  case "${option}" in
    h) usage; exit 1;;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    t) ;;
    v) ;;
    p) httpPort=$(trim "$OPTARG");;
    z) sslPort=$(trim "$OPTARG");;
    x) proxyHost=$(trim "$OPTARG");;
    y) proxyPort=$(trim "$OPTARG");;
    n) hostName=$(trim "$OPTARG");;
    o) serverName=$(trim "$OPTARG");;
    a) serverAlias=$(trim "$OPTARG");;
    e) scope=$(trim "$OPTARG");;
    c) code=$(trim "$OPTARG");;
    l) sslCertFile=$(trim "$OPTARG");;
    k) sslKeyFile=$(trim "$OPTARG");;
    r) sslTerminated=$(trim "$OPTARG");;
    f) forceSsl=$(trim "$OPTARG");;
    i) requireIp=$(trim "$OPTARG");;
    j) allowUrl=$(trim "$OPTARG");;
    b) basicAuthUserName=$(trim "$OPTARG");;
    s) ;;
    m) ;;
    d) magentoMode=$(trim "$OPTARG");;
    q) overwrite=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

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

if [[ -z "${hostName}" ]]; then
  echo "No host name specified!"
  usage
  exit 1
fi

if [[ -z "${serverName}" ]]; then
  echo "No server name specified!"
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

echo "Creating configuration at: /etc/apache2/sites-available/${hostName}.conf"

if [[ ${forceSsl} == "yes" ]] && [[ ${sslTerminated} == "no" ]]; then
  cat <<EOF | sudo tee "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
<VirtualHost *:${httpPort}>
  ServerName ${serverName}
EOF
  if [[ -n "${serverAlias}" ]]; then
    serverAliasList=( $(echo "${serverAlias}" | tr "," "\n") )
    for nextServerAlias in "${serverAliasList[@]}"; do
      cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  ServerAlias ${nextServerAlias}
EOF
    done
  fi
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  ServerAdmin webmaster@localhost
  DocumentRoot ${webPath}/
  Redirect / https://${serverName}/
</VirtualHost>
EOF
else
  cat <<EOF | sudo tee "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
<VirtualHost *:${httpPort}>
  ServerName ${serverName}
EOF
  if [[ -n "${serverAlias}" ]]; then
    serverAliasList=( $(echo "${serverAlias}" | tr "," "\n") )
    for nextServerAlias in "${serverAliasList[@]}"; do
      cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  ServerAlias ${nextServerAlias}
EOF
    done
  fi
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  ServerAdmin webmaster@localhost
  DocumentRoot ${webPath}/
  <Directory ${webPath}/>
EOF

  if [[ -n "${basicAuthUserName}" ]] && [[ "${basicAuthUserName}" != "-" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    AuthType Basic
    AuthName "${hostName}"
    AuthUserFile "${webRoot}/.htpasswd"
    Require valid-user
    Require ip 80.153.113.235
    Require ip 2003:a:771:7a00::/64
EOF
    if [[ -n "${requireIp}" ]]; then
      requireIpList=( $(echo "${requireIp}" | tr "," "\n") )
      for nextRequireIp in "${requireIpList[@]}"; do
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
      for requireIp in "${requireIpList[@]}"; do
        cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    SetEnvIF X-Forwarded-For "${requireIp}" AllowIP
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

    #SetEnvIf Request_URI ^/stripe/webhooks$ AllowUrl
    #Allow from env=AllowUrl
    #Allow from env=REDIRECT_AllowUrl

  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    Order Allow,Deny
    Satisfy any
    Options FollowSymLinks
    AllowOverride All
  </Directory>
EOF

  if [[ ${sslTerminated} == "yes" ]] && [[ -z "${proxyHost}" ]] && [[ -z "${proxyPort}" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  RewriteEngine On
  RewriteCond %{HTTP:X-Forwarded-Proto} =http
  RewriteRule .* https://%{HTTP:Host}%{REQUEST_URI} [L,R=permanent]
EOF
  fi

  if [[ ${sslTerminated} == "yes" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  SetEnv HTTPS on
EOF
  fi

  if [[ ${magentoMode} == "developer" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  SetEnv MAGE_IS_DEVELOPER_MODE "true"
EOF
  fi

  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
  SetEnv MAGE_RUN_TYPE "${scope}"
  SetEnv MAGE_RUN_CODE "${code}"
  LogLevel warn
  ErrorLog ${webRoot}/log/${hostName}-apache-http-error.log
  CustomLog ${webRoot}/log/${hostName}-apache-http-access.log custom
</VirtualHost>
EOF
fi

if [[ ${sslTerminated} == "no" ]]; then
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

cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
<IfModule mod_ssl.c>
  <VirtualHost *:${sslPort}>
    SSLEngine on
    SSLCertificateFile ${sslCertFile}
    SSLCertificateKeyFile ${sslKeyFile}
    ServerName ${serverName}
EOF
  if [[ -n "${serverAlias}" ]]; then
    serverAliasList=( $(echo "${serverAlias}" | tr "," "\n") )
    for nextServerAlias in "${serverAliasList[@]}"; do
      cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    ServerAlias ${nextServerAlias}
EOF
    done
  fi
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    ServerAdmin webmaster@localhost
    DocumentRoot ${webPath}/
    <Directory ${webPath}/>
EOF

  if [[ -n "${basicAuthUserName}" ]] && [[ "${basicAuthUserName}" != "-" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
      AuthType Basic
      AuthName "${hostName}"
      AuthUserFile "${webRoot}/.htpasswd"
      Require valid-user
      Require ip 80.153.113.235
      Require ip 2003:a:771:7a00::/64
EOF
    if [[ -n "${requireIp}" ]]; then
      requireIpList=( $(echo "${requireIp}" | tr "," "\n") )
      for nextRequireIp in "${requireIpList[@]}"; do
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
      for requireIp in "${requireIpList[@]}"; do
        cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
      SetEnvIF X-Forwarded-For "${requireIp}" AllowIP
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

      #SetEnvIf Request_URI ^/stripe/webhooks$ AllowUrl
      #Allow from env=AllowUrl
      #Allow from env=REDIRECT_AllowUrl

  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
      Order Allow,Deny
      Satisfy any
      Options FollowSymLinks
      AllowOverride All
    </Directory>
EOF

  if [[ ${magentoMode} == "developer" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    SetEnv MAGE_IS_DEVELOPER_MODE "true"
EOF
  fi

  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${hostName}.conf" > /dev/null
    SetEnv MAGE_RUN_TYPE "${scope}"
    SetEnv MAGE_RUN_CODE "${code}"
    LogLevel warn
    ErrorLog ${webRoot}/log/${hostName}-apache-ssl-error.log
    CustomLog ${webRoot}/log/${hostName}-apache-ssl-access.log custom
  </VirtualHost>
</IfModule>
EOF
fi

echo "Enabling configuration at: /etc/apache2/sites-enabled/${hostName}.conf"
test ! -f "/etc/apache2/sites-enabled/${hostName}.conf" && sudo a2ensite "${hostName}.conf"

if [[ ! -f /.dockerenv ]]; then
  echo "Restarting Apache"
  sudo service apache2 restart
  sleep 5
fi

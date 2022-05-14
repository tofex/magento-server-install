#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -n  Config name
  -v  Server name
  -b  Server Alias List, separated by comma
  -m  Magento mode (production or developer), default: production
  -r  Magento run type, default: website
  -c  Magento run code, default: base
  -t  SSL terminated (yes/no), default: no
  -f  Force SSL (yes/no), default: yes
  -u  Basic auth user name
  -p  Basic auth password
  -q  Allow IPs without basic auth, separated by comma
  -w  Web path
  -e  Web user, default: www-data
  -g  Web group, default: www-data
  -a  Apache HTTP port, default: 80
  -s  Apache SSL port, default: 443
  -i  Varnish port if required (optional)
  -l  SSL certificate file, default: /etc/ssl/certs/ssl-cert-snakeoil.pem
  -k  SSL key file, default: /etc/ssl/private/ssl-cert-snakeoil.key
  -o  Overwrite existing files (optional), default: no

Example: ${scriptName} -v project01.tofex.net -m production -r website -c base -t yes -f no -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

configName=
serverName=
serverAlias=
mageMode="production"
mageRunType="website"
mageRunCode="base"
sslTerminated="no"
forceSsl="yes"
basicAuthUserName=
basicAuthPassword=
requireIp=
webPath=
webUser="www-data"
webGroup="www-data"
apacheHttpPort="80"
apacheSslPort="443"
varnishPort=
sslCertFile=
sslKeyFile=
overwrite="no"

while getopts hn:v:b:m:r:c:t:f:u:p:q:w:e:g:a:s:i:l:k:o:? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) configName=$(trim "$OPTARG");;
    v) serverName=$(trim "$OPTARG");;
    b) serverAlias=$(trim "$OPTARG");;
    m) mageMode=$(trim "$OPTARG");;
    r) mageRunType=$(trim "$OPTARG");;
    c) mageRunCode=$(trim "$OPTARG");;
    t) sslTerminated=$(trim "$OPTARG");;
    f) forceSsl=$(trim "$OPTARG");;
    u) basicAuthUserName=$(trim "$OPTARG");;
    p) basicAuthPassword=$(trim "$OPTARG");;
    q) requireIp=$(trim "$OPTARG");;
    w) webPath=$(trim "$OPTARG");;
    e) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    a) apacheHttpPort=$(trim "$OPTARG");;
    s) apacheSslPort=$(trim "$OPTARG");;
    i) varnishPort=$(trim "$OPTARG");;
    l) sslCertFile=$(trim "$OPTARG");;
    k) sslKeyFile=$(trim "$OPTARG");;
    o) overwrite=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${configName}" ]]; then
  echo "No config name specified!"
  exit 1
fi

if [[ -z "${serverName}" ]]; then
  echo "No server name specified!"
  exit 1
fi

if [[ -z "${mageMode}" ]]; then
  echo "No mage mode specified!"
  exit 1
fi

if [[ -z "${mageRunType}" ]]; then
  echo "No mage run type specified!"
  exit 1
fi

if [[ -z "${mageRunCode}" ]]; then
  echo "No mage run code specified!"
  exit 1
fi

if [[ -z "${sslTerminated}" ]]; then
  echo "No SSL terminated specified!"
  exit 1
fi

if [[ -z "${forceSsl}" ]]; then
  echo "No force SSL specified!"
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ -z "${webUser}" ]]; then
  echo "No web user specified!"
  exit 1
fi

if [[ -z "${webGroup}" ]]; then
  echo "No web group specified!"
  exit 1
fi

if [[ -z "${apacheHttpPort}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ -z "${apacheSslPort}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ "${serverAlias}" == "-" ]]; then
  serverAlias=
fi

if [[ "${requireIp}" == "-" ]]; then
  requireIp=
fi

if [[ "${varnishPort}" == "-" ]]; then
  varnishPort=
fi

if [[ -z "${sslCertFile}" ]] || [[ "${sslCertFile}" == "-" ]]; then
  sslCertFile="/etc/ssl/certs/ssl-cert-snakeoil.pem"
fi

if [[ -z "${sslKeyFile}" ]] || [[ "${sslKeyFile}" == "-" ]]; then
  sslKeyFile="/etc/ssl/private/ssl-cert-snakeoil.key"
fi

currentUser="$(whoami)"
currentGroup="$(id -g -n)"

webRoot=$(dirname "${webPath}")

if [[ ! -d "${webRoot}" ]]; then
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    result=$(sudo -H -u "${webUser}" bash -c "mkdir -p ${webRoot}" 2>/dev/null && echo "1" || echo "0")
    if [[ "${result}" -eq 0 ]]; then
      result=$(sudo -H -u "${webUser}" bash -c "sudo mkdir -p ${webRoot}" 2>/dev/null && echo "1" || echo "0")
      if [[ "${result}" -eq 0 ]]; then
        sudo mkdir -p "${webRoot}"
        sudo chown "${webUser}":"${webGroup}" "${webRoot}"
      else
        sudo -H -u "${webUser}" bash -c "sudo chown ${webUser}:${webGroup} ${webRoot}"
      fi
    fi
  else
    sudo mkdir -p "${webRoot}"
    sudo chown "${webUser}":"${webGroup}" "${webRoot}"
  fi
fi

if [[ ! -d "${webPath}" ]]; then
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    result=$(sudo -H -u "${webUser}" bash -c "mkdir -p ${webPath}" 2>/dev/null && echo "1" || echo "0")
    if [[ "${result}" -eq 0 ]]; then
      result=$(sudo -H -u "${webUser}" bash -c "sudo mkdir -p ${webPath}" 2>/dev/null && echo "1" || echo "0")
      if [[ "${result}" -eq 0 ]]; then
        sudo mkdir -p "${webPath}"
        sudo chown "${webUser}":"${webGroup}" "${webPath}"
      else
        sudo -H -u "${webUser}" bash -c "sudo chown ${webUser}:${webGroup} ${webPath}"
      fi
    fi
  else
    sudo mkdir -p "${webPath}"
    sudo chown "${webUser}":"${webGroup}" "${webPath}"
  fi
fi

if [[ ! -d "${webRoot}/log" ]]; then
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    result=$(sudo -H -u "${webUser}" bash -c "mkdir -p ${webRoot}/log/" 2>/dev/null && echo "1" || echo "0")
    if [[ "${result}" -eq 0 ]]; then
      result=$(sudo -H -u "${webUser}" bash -c "sudo mkdir -p ${webRoot}/log/" 2>/dev/null && echo "1" || echo "0")
      if [[ "${result}" -eq 0 ]]; then
        sudo mkdir -p "${webRoot}/log/"
        sudo chown "${webUser}":"${webGroup}" "${webRoot}/log/"
      else
        sudo -H -u "${webUser}" bash -c "sudo chown ${webUser}:${webGroup} ${webRoot}/log/"
      fi
    fi
  else
    sudo mkdir -p "${webRoot}/log/"
    sudo chown "${webUser}":"${webGroup}" "${webRoot}/log/"
  fi
fi

if [[ -n "${basicAuthUserName}" ]] && [[ "${basicAuthUserName}" != "-" ]]; then
  echo "Adding basic user in file at: ${webRoot}/.htpasswd"
  if [[ -f "${webRoot}/.htpasswd" ]]; then
    sudo htpasswd -b "${webRoot}/.htpasswd" "${basicAuthUserName}" "${basicAuthPassword}"
  else
    sudo htpasswd -b -c "${webRoot}/.htpasswd" "${basicAuthUserName}" "${basicAuthPassword}"
  fi
fi

if [[ "${overwrite}" == "no" ]]; then
  if [[ -f "/etc/apache2/sites-available/${configName}.conf" ]]; then
    echo "Configuration \"/etc/apache2/sites-available/${configName}.conf\" already exists"
    exit 1
  fi
else
  if [[ -f "/etc/apache2/sites-available/${configName}.conf" ]]; then
    echo "Copying configuration from \"/etc/apache2/sites-available/${configName}.conf\" to \"/etc/apache2/sites-available/${configName}.conf.old\""
    sudo cp "/etc/apache2/sites-available/${configName}.conf" "/etc/apache2/sites-available/${configName}.conf.old"
  fi
fi

echo "Creating log format configuration at: /etc/apache2/conf-available/log.conf"
cat <<EOF | sudo tee /etc/apache2/conf-available/log.conf > /dev/null
SetEnvIfNoCase User-Agent "007ac9" Bot=1
SetEnvIfNoCase User-Agent "360Spider" Bot=1
SetEnvIfNoCase User-Agent "Aboundexbot" Bot=1
SetEnvIfNoCase User-Agent "acebookexternalhit" Bot=1
SetEnvIfNoCase User-Agent "adbeat_bot" Bot=1
SetEnvIfNoCase User-Agent "AdBot" Bot=1
SetEnvIfNoCase User-Agent "AddThis" Bot=1
SetEnvIfNoCase User-Agent "adreview" Bot=1
SetEnvIfNoCase User-Agent "AdsBot-Google-Mobile" Bot=1
SetEnvIfNoCase User-Agent "AdsBot-Google" Bot=1
SetEnvIfNoCase User-Agent "Adsbot" Bot=1
SetEnvIfNoCase User-Agent "adscanner" Bot=1
SetEnvIfNoCase User-Agent "AdvBot" Bot=1
SetEnvIfNoCase User-Agent "AhrefsBot" Bot=1
SetEnvIfNoCase User-Agent "aiHitBot" Bot=1
SetEnvIfNoCase User-Agent "aiohttp" Bot=1
SetEnvIfNoCase User-Agent "AlphaBot" Bot=1
SetEnvIfNoCase User-Agent "AlphaSeoBot-SA" Bot=1
SetEnvIfNoCase User-Agent "AlphaSeoBot" Bot=1
SetEnvIfNoCase User-Agent "Apache-HttpClient" Bot=1
SetEnvIfNoCase User-Agent "Applebot" Bot=1
SetEnvIfNoCase User-Agent "archive.org_bot" Bot=1
SetEnvIfNoCase User-Agent "AspiegelBot" Bot=1
SetEnvIfNoCase User-Agent "at-bot" Bot=1
SetEnvIfNoCase User-Agent "audisto-essential" Bot=1
SetEnvIfNoCase User-Agent "audisto" Bot=1
SetEnvIfNoCase User-Agent "AwarioRssBot" Bot=1
SetEnvIfNoCase User-Agent "AwarioSmartBot" Bot=1
SetEnvIfNoCase User-Agent "axios" Bot=1
SetEnvIfNoCase User-Agent "BacklinkCrawler" Bot=1
SetEnvIfNoCase User-Agent "Baiduspider" Bot=1
SetEnvIfNoCase User-Agent "Barkrowler" Bot=1
SetEnvIfNoCase User-Agent "BegunAdvertising" Bot=1
SetEnvIfNoCase User-Agent "betaBot" Bot=1
SetEnvIfNoCase User-Agent "billigerbot" Bot=1
SetEnvIfNoCase User-Agent "bingbot" Bot=1
SetEnvIfNoCase User-Agent "BingPreview" Bot=1
SetEnvIfNoCase User-Agent "bitlybot" Bot=1
SetEnvIfNoCase User-Agent "BLEXBot" Bot=1
SetEnvIfNoCase User-Agent "BoogleBot" Bot=1
SetEnvIfNoCase User-Agent "BUbiNG" Bot=1
SetEnvIfNoCase User-Agent "Buck" Bot=1
SetEnvIfNoCase User-Agent "BuckyOHare" Bot=1
SetEnvIfNoCase User-Agent "ca-crawler" Bot=1
SetEnvIfNoCase User-Agent "calculon" Bot=1
SetEnvIfNoCase User-Agent "careerbot" Bot=1
SetEnvIfNoCase User-Agent "CatchBot" Bot=1
SetEnvIfNoCase User-Agent "CCBot" Bot=1
SetEnvIfNoCase User-Agent "CheckMarkNetwork" Bot=1
SetEnvIfNoCase User-Agent "Cliqzbot" Bot=1
SetEnvIfNoCase User-Agent "CloudFlare-AlwaysOnline" Bot=1
SetEnvIfNoCase User-Agent "CMS Crawler" Bot=1
SetEnvIfNoCase User-Agent "coccocbot-image" Bot=1
SetEnvIfNoCase User-Agent "coccocbot-web" Bot=1
SetEnvIfNoCase User-Agent "CompSpyBot" Bot=1
SetEnvIfNoCase User-Agent "crawler_eb_germany_2.0" Bot=1
SetEnvIfNoCase User-Agent "crawler4j" Bot=1
SetEnvIfNoCase User-Agent "CrazyWebCrawler-Spider" Bot=1
SetEnvIfNoCase User-Agent "CrowdTanglebot" Bot=1
SetEnvIfNoCase User-Agent "CukBot" Bot=1
SetEnvIfNoCase User-Agent "curl" Bot=1
SetEnvIfNoCase User-Agent "Dataprovider" Bot=1
SetEnvIfNoCase User-Agent "deepcrawl" Bot=1
SetEnvIfNoCase User-Agent "DER-bot" Bot=1
SetEnvIfNoCase User-Agent "DF Bot" Bot=1
SetEnvIfNoCase User-Agent "Diffbot" Bot=1
SetEnvIfNoCase User-Agent "dlvr.it" Bot=1
SetEnvIfNoCase User-Agent "DomainAppender" Bot=1
SetEnvIfNoCase User-Agent "DomainStatsBot" Bot=1
SetEnvIfNoCase User-Agent "dotbot" Bot=1
SetEnvIfNoCase User-Agent "dubaiindex" Bot=1
SetEnvIfNoCase User-Agent "DuckDuckBot" Bot=1
SetEnvIfNoCase User-Agent "DuckDuckGo-Favicons-Bot" Bot=1
SetEnvIfNoCase User-Agent "duggmirror" Bot=1
SetEnvIfNoCase User-Agent "e.ventures Investment Crawler" Bot=1
SetEnvIfNoCase User-Agent "ElectricMonk" Bot=1
SetEnvIfNoCase User-Agent "envolk" Bot=1
SetEnvIfNoCase User-Agent "evc-batch" Bot=1
SetEnvIfNoCase User-Agent "ExpertSearchSpider" Bot=1
SetEnvIfNoCase User-Agent "ExtLinksBot" Bot=1
SetEnvIfNoCase User-Agent "extraplus-robot" Bot=1
SetEnvIfNoCase User-Agent "eZ Publish" Bot=1
SetEnvIfNoCase User-Agent "facebookcatalog" Bot=1
SetEnvIfNoCase User-Agent "facebookexternalhit" Bot=1
SetEnvIfNoCase User-Agent "facebookexternalua" Bot=1
SetEnvIfNoCase User-Agent "Fatbot" Bot=1
SetEnvIfNoCase User-Agent "FeedBot" Bot=1
SetEnvIfNoCase User-Agent "Findxbot" Bot=1
SetEnvIfNoCase User-Agent "fr-crawler" Bot=1
SetEnvIfNoCase User-Agent "GarlikCrawler" Bot=1
SetEnvIfNoCase User-Agent "Gather Analyze Provide" Bot=1
SetEnvIfNoCase User-Agent "Genieo" Bot=1
SetEnvIfNoCase User-Agent "gloomarbot" Bot=1
SetEnvIfNoCase User-Agent "Gluten Free Crawler" Bot=1
SetEnvIfNoCase User-Agent "Go-http-client" Bot=1
SetEnvIfNoCase User-Agent "Google-Adwords-Instant" Bot=1
SetEnvIfNoCase User-Agent "Google-Site-Verification" Bot=1
SetEnvIfNoCase User-Agent "Googlebot" Bot=1
SetEnvIfNoCase User-Agent "GoogleDocs" Bot=1
SetEnvIfNoCase User-Agent "GoogleImageProxy" Bot=1
SetEnvIfNoCase User-Agent "grapeshot" Bot=1
SetEnvIfNoCase User-Agent "GuzzleHttp" Bot=1
SetEnvIfNoCase User-Agent "HeadlessChrome" Bot=1
SetEnvIfNoCase User-Agent "hokifyBot" Bot=1
SetEnvIfNoCase User-Agent "HTTrack" Bot=1
SetEnvIfNoCase User-Agent "HuaweiSymantecSpider" Bot=1
SetEnvIfNoCase User-Agent "HubSpot Crawler" Bot=1
SetEnvIfNoCase User-Agent "HubSpot Links Crawler" Bot=1
SetEnvIfNoCase User-Agent "HyperCrawl" Bot=1
SetEnvIfNoCase User-Agent "HypeStat" Bot=1
SetEnvIfNoCase User-Agent "ias_crawler" Bot=1
SetEnvIfNoCase User-Agent "ICCrawler - iCjobs" Bot=1
SetEnvIfNoCase User-Agent "idealo-bot" Bot=1
SetEnvIfNoCase User-Agent "idmarch" Bot=1
SetEnvIfNoCase User-Agent "ImplisenseBot" Bot=1
SetEnvIfNoCase User-Agent "Internet-structure-research-project-bot" Bot=1
SetEnvIfNoCase User-Agent "IonCrawl" Bot=1
SetEnvIfNoCase User-Agent "ips-agent" Bot=1
SetEnvIfNoCase User-Agent "IRLbot" Bot=1
SetEnvIfNoCase User-Agent "JamesBOT" Bot=1
SetEnvIfNoCase User-Agent "Jersey" Bot=1
SetEnvIfNoCase User-Agent "JobboerseBot" Bot=1
SetEnvIfNoCase User-Agent "JobdiggerSpider" Bot=1
SetEnvIfNoCase User-Agent "Jobsearch" Bot=1
SetEnvIfNoCase User-Agent "kalooga" Bot=1
SetEnvIfNoCase User-Agent "KiobiBot" Bot=1
SetEnvIfNoCase User-Agent "Klarnabot-Image" Bot=1
SetEnvIfNoCase User-Agent "Kraken" Bot=1
SetEnvIfNoCase User-Agent "larbin" Bot=1
SetEnvIfNoCase User-Agent "Leuchtfeuer Crawler" Bot=1
SetEnvIfNoCase User-Agent "LightspeedSystemsCrawler" Bot=1
SetEnvIfNoCase User-Agent "linkdexbot" Bot=1
SetEnvIfNoCase User-Agent "linkfluence" Bot=1
SetEnvIfNoCase User-Agent "LinkpadBot" Bot=1
SetEnvIfNoCase User-Agent "Lipperhey" Bot=1
SetEnvIfNoCase User-Agent "LSSRocketCrawler" Bot=1
SetEnvIfNoCase User-Agent "ltx71" Bot=1
SetEnvIfNoCase User-Agent "M2E Pro Cron" Bot=1
SetEnvIfNoCase User-Agent "magpie-crawler" Bot=1
SetEnvIfNoCase User-Agent "Mail.RU_Bot" Bot=1
SetEnvIfNoCase User-Agent "Mappy" Bot=1
SetEnvIfNoCase User-Agent "masscan" Bot=1
SetEnvIfNoCase User-Agent "MauiBot" Bot=1
SetEnvIfNoCase User-Agent "MBCrawler" Bot=1
SetEnvIfNoCase User-Agent "meanpathbot" Bot=1
SetEnvIfNoCase User-Agent "Mediatoolkitbot" Bot=1
SetEnvIfNoCase User-Agent "MegaIndex.ru" Bot=1
SetEnvIfNoCase User-Agent "metajobbot" Bot=1
SetEnvIfNoCase User-Agent "MetaJobBot" Bot=1
SetEnvIfNoCase User-Agent "Microsoft Office" Bot=1
SetEnvIfNoCase User-Agent "MixnodeCache" Bot=1
SetEnvIfNoCase User-Agent "MJ12bot" Bot=1
SetEnvIfNoCase User-Agent "MojeekBot" Bot=1
SetEnvIfNoCase User-Agent "MRSPUTNIK" Bot=1
SetEnvIfNoCase User-Agent "MSIECrawler" Bot=1
SetEnvIfNoCase User-Agent "msnbot" Bot=1
SetEnvIfNoCase User-Agent "MxToolbox" Bot=1
SetEnvIfNoCase User-Agent "nbot" Bot=1
SetEnvIfNoCase User-Agent "neofonie" Bot=1
SetEnvIfNoCase User-Agent "NerdyBot" Bot=1
SetEnvIfNoCase User-Agent "NetcraftSurveyAgent" Bot=1
SetEnvIfNoCase User-Agent "netEstate NE Crawler" Bot=1
SetEnvIfNoCase User-Agent "NetpeakSpiderBot" Bot=1
SetEnvIfNoCase User-Agent "netseer" Bot=1
SetEnvIfNoCase User-Agent "NetSystemsResearch" Bot=1
SetEnvIfNoCase User-Agent "NextGenSearchBot" Bot=1
SetEnvIfNoCase User-Agent "Nimbostratus-Bot" Bot=1
SetEnvIfNoCase User-Agent "node-fetch" Bot=1
SetEnvIfNoCase User-Agent "nsrbot" Bot=1
SetEnvIfNoCase User-Agent "Nutch" Bot=1
SetEnvIfNoCase User-Agent "oBot" Bot=1
SetEnvIfNoCase User-Agent "OdklBot" Bot=1
SetEnvIfNoCase User-Agent "odysseus" Bot=1
SetEnvIfNoCase User-Agent "okhttp" Bot=1
SetEnvIfNoCase User-Agent "OpenindexSpider" Bot=1
SetEnvIfNoCase User-Agent "OpenStreetMap" Bot=1
SetEnvIfNoCase User-Agent "Pandalytics" Bot=1
SetEnvIfNoCase User-Agent "panscient.com" Bot=1
SetEnvIfNoCase User-Agent "Payment Network AG" Bot=1
SetEnvIfNoCase User-Agent "PayPal IPN" Bot=1
SetEnvIfNoCase User-Agent "PetalBot" Bot=1
SetEnvIfNoCase User-Agent "Photon" Bot=1
SetEnvIfNoCase User-Agent "pimeyes.com crawler" Bot=1
SetEnvIfNoCase User-Agent "Pingdom.com_bot" Bot=1
SetEnvIfNoCase User-Agent "Pinterestbot" Bot=1
SetEnvIfNoCase User-Agent "PiplBot" Bot=1
SetEnvIfNoCase User-Agent "plukkie" Bot=1
SetEnvIfNoCase User-Agent "PocketImageCache" Bot=1
SetEnvIfNoCase User-Agent "Pockey-GetHTML" Bot=1
SetEnvIfNoCase User-Agent "probethenet" Bot=1
SetEnvIfNoCase User-Agent "proximic" Bot=1
SetEnvIfNoCase User-Agent "Pu_iN" Bot=1
SetEnvIfNoCase User-Agent "pub-crawler" Bot=1
SetEnvIfNoCase User-Agent "PubMatic" Bot=1
SetEnvIfNoCase User-Agent "python-requests" Bot=1
SetEnvIfNoCase User-Agent "Qwantify" Bot=1
SetEnvIfNoCase User-Agent "Radian6" Bot=1
SetEnvIfNoCase User-Agent "RankSonicSiteAuditor" Bot=1
SetEnvIfNoCase User-Agent "RavenCrawler" Bot=1
SetEnvIfNoCase User-Agent "RED" Bot=1
SetEnvIfNoCase User-Agent "RedesScrapy" Bot=1
SetEnvIfNoCase User-Agent "ResearchBot" Bot=1
SetEnvIfNoCase User-Agent "Riddler" Bot=1
SetEnvIfNoCase User-Agent "Riddler" Bot=1
SetEnvIfNoCase User-Agent "robots" Bot=1
SetEnvIfNoCase User-Agent "rogerbot" Bot=1
SetEnvIfNoCase User-Agent "RyteBot" Bot=1
SetEnvIfNoCase User-Agent "SafeDNSBot" Bot=1
SetEnvIfNoCase User-Agent "SBSearch" Bot=1
SetEnvIfNoCase User-Agent "Schottenland-Bot" Bot=1
SetEnvIfNoCase User-Agent "ScoutJet" Bot=1
SetEnvIfNoCase User-Agent "Screaming Frog SEO Spider" Bot=1
SetEnvIfNoCase User-Agent "Seekport Crawler" Bot=1
SetEnvIfNoCase User-Agent "seewithkids.com" Bot=1
SetEnvIfNoCase User-Agent "SemrushBot" Bot=1
SetEnvIfNoCase User-Agent "SEMrushBot" Bot=1
SetEnvIfNoCase User-Agent "sentibot" Bot=1
SetEnvIfNoCase User-Agent "SeobilityBot" Bot=1
SetEnvIfNoCase User-Agent "seocharger-robot" Bot=1
SetEnvIfNoCase User-Agent "seocompany" Bot=1
SetEnvIfNoCase User-Agent "SEOkicks-Robot" Bot=1
SetEnvIfNoCase User-Agent "SEOkicks" Bot=1
SetEnvIfNoCase User-Agent "SEOlyticsCrawler" Bot=1
SetEnvIfNoCase User-Agent "seoscanners.net" Bot=1
SetEnvIfNoCase User-Agent "serpstatbot" Bot=1
SetEnvIfNoCase User-Agent "SeznamBot" Bot=1
SetEnvIfNoCase User-Agent "sg-Orbiter" Bot=1
SetEnvIfNoCase User-Agent "ShoopBot" Bot=1
SetEnvIfNoCase User-Agent "sistrix" Bot=1
SetEnvIfNoCase User-Agent "SiteExplorer" Bot=1
SetEnvIfNoCase User-Agent "SiteSucker" Bot=1
SetEnvIfNoCase User-Agent "sixclicks OnPage Check" Bot=1
SetEnvIfNoCase User-Agent "SkypeUriPreview" Bot=1
SetEnvIfNoCase User-Agent "Slack-ImgProxy" Bot=1
SetEnvIfNoCase User-Agent "Slackbot-LinkExpanding" Bot=1
SetEnvIfNoCase User-Agent "Slackbot" Bot=1
SetEnvIfNoCase User-Agent "SmabblerBot" Bot=1
SetEnvIfNoCase User-Agent "SMTBot" Bot=1
SetEnvIfNoCase User-Agent "Snapchat" Bot=1
SetEnvIfNoCase User-Agent "sogou spider" Bot=1
SetEnvIfNoCase User-Agent "Sogou web spider" Bot=1
SetEnvIfNoCase User-Agent "spbot" Bot=1
SetEnvIfNoCase User-Agent "SpiderLing" Bot=1
SetEnvIfNoCase User-Agent "Spiderlytics" Bot=1
SetEnvIfNoCase User-Agent "sSearch Crawler" Bot=1
SetEnvIfNoCase User-Agent "ssearch_bot" Bot=1
SetEnvIfNoCase User-Agent "startmebot" Bot=1
SetEnvIfNoCase User-Agent "StatusCake" Bot=1
SetEnvIfNoCase User-Agent "Steeler" Bot=1
SetEnvIfNoCase User-Agent "stq_bot" Bot=1
SetEnvIfNoCase User-Agent "SurdotlyBot" Bot=1
SetEnvIfNoCase User-Agent "SurveyBot" Bot=1
SetEnvIfNoCase User-Agent "Swiftbot" Bot=1
SetEnvIfNoCase User-Agent "Taboolabot" Bot=1
SetEnvIfNoCase User-Agent "TelegramBot" Bot=1
SetEnvIfNoCase User-Agent "Test Certificate Info" Bot=1
SetEnvIfNoCase User-Agent "The Knowledge AI" Bot=1
SetEnvIfNoCase User-Agent "thumbshots-de-bot" Bot=1
SetEnvIfNoCase User-Agent "ThumbSniper" Bot=1
SetEnvIfNoCase User-Agent "Thunderbird" Bot=1
SetEnvIfNoCase User-Agent "thunderstone" Bot=1
SetEnvIfNoCase User-Agent "TinEye" Bot=1
SetEnvIfNoCase User-Agent "Toplistbot" Bot=1
SetEnvIfNoCase User-Agent "TosCrawler" Bot=1
SetEnvIfNoCase User-Agent "TprAdsTxtCrawler" Bot=1
SetEnvIfNoCase User-Agent "tracking-quality-spider" Bot=1
SetEnvIfNoCase User-Agent "trendictionbot" Bot=1
SetEnvIfNoCase User-Agent "TrendsmapResolver" Bot=1
SetEnvIfNoCase User-Agent "Turnitin" Bot=1
SetEnvIfNoCase User-Agent "TurnitinBot" Bot=1
SetEnvIfNoCase User-Agent "TweetmemeBot" Bot=1
SetEnvIfNoCase User-Agent "Twitterbot" Bot=1
SetEnvIfNoCase User-Agent "uCrawler" Bot=1
SetEnvIfNoCase User-Agent "Uptimebot" Bot=1
SetEnvIfNoCase User-Agent "uptimerobot" Bot=1
SetEnvIfNoCase User-Agent "Vagabondo" Bot=1
SetEnvIfNoCase User-Agent "vebidoobot" Bot=1
SetEnvIfNoCase User-Agent "VeBot" Bot=1
SetEnvIfNoCase User-Agent "VelenPublicWebCrawler" Bot=1
SetEnvIfNoCase User-Agent "voltron" Bot=1
SetEnvIfNoCase User-Agent "VsuSearchSpider" Bot=1
SetEnvIfNoCase User-Agent "WBSearchBot" Bot=1
SetEnvIfNoCase User-Agent "webmeasurement-bot" Bot=1
SetEnvIfNoCase User-Agent "Website-audit.be Crawler" Bot=1
SetEnvIfNoCase User-Agent "wein.cc/2.0" Bot=1
SetEnvIfNoCase User-Agent "WeinPlusShoppingBot" Bot=1
SetEnvIfNoCase User-Agent "WeSEE" Bot=1
SetEnvIfNoCase User-Agent "WeViKaBot" Bot=1
SetEnvIfNoCase User-Agent "Wget" Bot=1
SetEnvIfNoCase User-Agent "WhatsApp" Bot=1
SetEnvIfNoCase User-Agent "WikiDo" Bot=1
SetEnvIfNoCase User-Agent "willnorris/imageproxy" Bot=1
SetEnvIfNoCase User-Agent "wonderbot" Bot=1
SetEnvIfNoCase User-Agent "WordPress" Bot=1
SetEnvIfNoCase User-Agent "wotbox" Bot=1
SetEnvIfNoCase User-Agent "WPImageProxy" Bot=1
SetEnvIfNoCase User-Agent "x28-job-bot" Bot=1
SetEnvIfNoCase User-Agent "x64-criteo" Bot=1
SetEnvIfNoCase User-Agent "XenForo" Bot=1
SetEnvIfNoCase User-Agent "XoviBot" Bot=1
SetEnvIfNoCase User-Agent "Yahoo\! Slurp" Bot=1
SetEnvIfNoCase User-Agent "YahooMailProxy" Bot=1
SetEnvIfNoCase User-Agent "YandexBot" Bot=1
SetEnvIfNoCase User-Agent "YandexImageResizer" Bot=1
SetEnvIfNoCase User-Agent "YandexImages" Bot=1
SetEnvIfNoCase User-Agent "YandexMetrika" Bot=1
SetEnvIfNoCase User-Agent "YisouSpider" Bot=1
SetEnvIfNoCase User-Agent "ZoomBot" Bot=1
SetEnvIfNoCase Bot "^$" Bot=0
SetEnvIfNoCase User-Agent "CFNetwork/[0-9]+ Darwin" Mobile 1
SetEnvIfNoCase User-Agent "CFNetwork/[0-9]+.[0-9]+ Darwin" Mobile 1
SetEnvIfNoCase User-Agent "CFNetwork/[0-9]+.[0-9]+.[0-9]+ Darwin" Mobile 1
SetEnvIfNoCase User-Agent "Dalvik/[0-9]+.[0-9]+.[0-9]+ \(Linux; U; Android [0-9]+" Mobile 1
SetEnvIfNoCase User-Agent "FBAN/FB4A" Mobile=1
SetEnvIfNoCase User-Agent "Mobile Safari" Mobile=1
SetEnvIfNoCase User-Agent "Mozilla/[0-9]+.0 \(Android; Mobile" Mobile=1
SetEnvIfNoCase User-Agent "Mozilla/[0-9]+.0 \(Android [0-9]+; Mobile" Mobile=1
SetEnvIfNoCase User-Agent "Mozilla/[0-9]+.0 \(Android [0-9]+.[0-9]+; Mobile" Mobile=1
SetEnvIfNoCase User-Agent "Mozilla/[0-9]+.0 \(Android [0-9]+.[0-9]+.[0-9]+; Mobile" Mobile=1
SetEnvIfNoCase User-Agent "Mozilla/[0-9]+.0 \(Android; Tablet" Mobile=1
SetEnvIfNoCase User-Agent "Mozilla/[0-9]+.0 \(compatible; MSIE [0-9]+\.0; Windows Phone" Mobile=1
SetEnvIfNoCase User-Agent "Mozilla/[0-9]+.0 \(iPhone" Mobile=1
SetEnvIfNoCase User-Agent "Mozilla/[0-9]+.0 \(iPad" Mobile=1
SetEnvIfNoCase User-Agent "Mozilla/[0-9]+.0 \(iPod" Mobile=1
SetEnvIfNoCase User-Agent "Mozilla/[0-9]+.0 \(Linux; Android" Mobile=1
SetEnvIfNoCase User-Agent "Mozilla/[0-9]+.0 \(Mobile" Mobile=1
SetEnvIfNoCase User-Agent "Mozilla/[0-9]+.0 \(PlayBook; U; RIM Tablet OS" Mobile=1
SetEnvIfNoCase User-Agent "Mozilla/[0-9]+.0 \(Windows Phone" Mobile=1
SetEnvIfNoCase User-Agent "Opera Mini" Mobile=1
SetEnvIfNoCase User-Agent "platform:server_android" Mobile=1
SetEnvIfNoCase Mobile "^$" Mobile=0
SetEnvIfNoCase Request_URI "\.(atom|bmp|bz2|css|doc|docx|eot|exe|gif|gz|ico|jpeg|jpg|js|mid|midi|mp4|ogg|ogv|otf|pdf|png|ppt|rar|rss|rtf|svg|svgz|swf|tar|tif|tgz|ttf|txt|wav|woff|woff2|xml|xls|xlsx|zip|ATOM|BMP|BZ2|CSS|DOC|DOCX|EOT|EXE|GIF|GZ|ICO|JPEG|JPG|JS|MID|MIDI|MP4|OGG|OGV|OTF|PDF|PNG|PPT|RAR|RSS|RTF|SVG|SVGZ|SWF|TAR|TIF|TGZ|TTF|TXT|WAV|WOFF|WOFF2|XML|XLS|XLSX|ZIP)$" StaticContent
SetEnvIfNoCase StaticContent "^$" StaticContent=0
LogFormat "%t [%{X-Forwarded-For}i] [%a] [%m] [%U%q] [%{Referer}i] [%{User-agent}i] [%>s] [%D] [%O] [%{Bot}e] [%{Mobile}e] [%{StaticContent}e]" custom
EOF

if [[ ! -f /etc/apache2/conf-enabled/log.conf ]]; then
  echo "Enabling configuration at: /etc/apache2/conf-enabled/log.conf"
  sudo a2enconf log
fi

echo "Creating configuration at: /etc/apache2/sites-available/${configName}.conf"

if [[ "${forceSsl}" == "yes" ]] && [[ "${sslTerminated}" == "no" ]]; then
  echo "Adding HTTP configuration for port: ${apacheHttpPort} and server name: ${serverName}"
  cat <<EOF | sudo tee "/etc/apache2/sites-available/${configName}.conf" > /dev/null
<VirtualHost *:${apacheHttpPort}>
  ServerName ${serverName}
EOF
  if [[ -n "${serverAlias}" ]]; then
    serverAliasList=( $(echo "${serverAlias}" | tr "," "\n") )
    for nextServerAlias in "${serverAliasList[@]}"; do
      echo "Adding HTTP server alias: ${nextServerAlias}"
      cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
  ServerAlias ${nextServerAlias}
EOF
    done
  fi
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
  ServerAdmin webmaster@localhost
  DocumentRoot ${webPath}/
  Redirect / https://${serverName}/
</VirtualHost>
EOF
else
  cat <<EOF | sudo tee "/etc/apache2/sites-available/${configName}.conf" > /dev/null
<VirtualHost *:${apacheHttpPort}>
  ServerName ${serverName}
EOF
  if [[ -n "${serverAlias}" ]]; then
    serverAliasList=( $(echo "${serverAlias}" | tr "," "\n") )
    for nextServerAlias in "${serverAliasList[@]}"; do
      cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
  ServerAlias ${nextServerAlias}
EOF
    done
  fi
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
  ServerAdmin webmaster@localhost
  DocumentRoot ${webPath}/
  <Directory ${webPath}/>
EOF

  if [[ -n "${basicAuthUserName}" ]] && [[ "${basicAuthUserName}" != "-" ]]; then
    echo "Adding basic auth authorization with name: ${configName}"
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
    AuthType Basic
    AuthName "${configName}"
    AuthUserFile "${webRoot}/.htpasswd"
    Require valid-user
    Require ip 80.153.113.235
    Require ip 2003:a:771:7a00::/64
EOF
    if [[ -n "${requireIp}" ]]; then
      requireIpList=( $(echo "${requireIp}" | tr "," "\n") )
      for nextRequireIp in "${requireIpList[@]}"; do
        echo "Adding basic auth exception for remote IP: ${nextRequireIp}"
        cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
    Require ip ${nextRequireIp}
EOF
      done
    fi
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
    SetEnvIF X-Forwarded-For "80.153.113.235" AllowIP
    SetEnvIF X-Forwarded-For "2003:a:771:7a00:.*" AllowIP
EOF
    if [[ -n "${requireIp}" ]]; then
      requireIpList=( $(echo "${requireIp}" | tr "," "\n") )
      for nextRequireIp in "${requireIpList[@]}"; do
        echo "Adding basic auth exception for forwarded IP: ${nextRequireIp}"
        cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
    SetEnvIF X-Forwarded-For "${nextRequireIp}" AllowIP
EOF
      done
    fi
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
    Require env AllowIP
EOF
  fi

  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
    Options FollowSymLinks
    AllowOverride All
    Order Allow,Deny
    Allow from all
  </Directory>
EOF

  if [[ "${sslTerminated}" == "yes" ]] && [[ -z "${varnishPort}" ]]; then
    echo "Adding SSL rewrite for HTTP access"
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
  RewriteEngine On
  RewriteCond %{HTTP:X-Forwarded-Proto} =http
  RewriteRule .* https://%{HTTP:Host}%{REQUEST_URI} [L,R=permanent]
EOF
  fi

  if [[ "${sslTerminated}" == "yes" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
  SetEnv HTTPS on
EOF
  fi

  echo "Setting Magento entry with type: ${mageRunType} and code: ${mageRunCode}"
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
  SetEnv MAGE_MODE "${mageMode}"
EOF
  if [[ "${mageRunType}" != "default" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
  SetEnv MAGE_RUN_TYPE "${mageRunType}"
EOF
  fi
  if [[ "${mageRunCode}" != "default" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
  SetEnv MAGE_RUN_CODE "${mageRunCode}"
EOF
  fi
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
  LogLevel warn
  ErrorLog ${webRoot}/log/${configName}-apache-http-error.log
  CustomLog ${webRoot}/log/${configName}-apache-http-access.log custom
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
<VirtualHost *:${apacheHttpPort}>
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
  <VirtualHost *:${apacheSslPort}>
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

  echo "Adding SSL configuration with port: ${apacheSslPort} and server name: ${serverName}"
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
<IfModule mod_ssl.c>
  <VirtualHost *:${apacheSslPort}>
    SSLEngine on
    SSLCertificateFile ${sslCertFile}
    SSLCertificateKeyFile ${sslKeyFile}
    ServerName ${serverName}
EOF
  if [[ -n "${serverAlias}" ]]; then
    serverAliasList=( $(echo "${serverAlias}" | tr "," "\n") )
    for nextServerAlias in "${serverAliasList[@]}"; do
      echo "Adding SSL server alias: ${nextServerAlias}"
      cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
    ServerAlias ${nextServerAlias}
EOF
    done
  fi
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
    ServerAdmin webmaster@localhost
    DocumentRoot ${webPath}/
    <Directory ${webPath}/>
EOF

  if [[ -n "${basicAuthUserName}" ]] && [[ "${basicAuthUserName}" != "-" ]]; then
    echo "Adding basic auth authorization with name: ${configName}"
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
      AuthType Basic
      AuthName "${configName}"
      AuthUserFile "${webRoot}/.htpasswd"
      Require valid-user
      Require ip 80.153.113.235
      Require ip 2003:a:771:7a00::/64
EOF
      if [[ -n "${requireIp}" ]]; then
        requireIpList=( $(echo "${requireIp}" | tr "," "\n") )
        for nextRequireIp in "${requireIpList[@]}"; do
          echo "Adding basic auth exception for remote IP: ${nextRequireIp}"
          cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
      Require ip ${nextRequireIp}
EOF
        done
      fi
      cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
      SetEnvIF X-Forwarded-For "80.153.113.235" AllowIP
      SetEnvIF X-Forwarded-For "2003:a:771:7a00:.*" AllowIP
EOF
      if [[ -n "${requireIp}" ]]; then
        requireIpList=( $(echo "${requireIp}" | tr "," "\n") )
        for nextRequireIp in "${requireIpList[@]}"; do
          echo "Adding basic auth exception for forwarded IP: ${nextRequireIp}"
          cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
      SetEnvIF X-Forwarded-For "${nextRequireIp}" AllowIP
EOF
        done
      fi
      cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
      Require env AllowIP
EOF
  fi

  echo "Setting Magento entry with type: ${mageRunType} and code: ${mageRunCode}"
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
      Options FollowSymLinks
      AllowOverride All
      Order Allow,Deny
      Allow from all
    </Directory>
    SetEnv MAGE_MODE "${mageMode}"
EOF
  if [[ "${mageRunType}" != "default" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
    SetEnv MAGE_RUN_TYPE "${mageRunType}"
EOF
  fi
  if [[ "${mageRunCode}" != "default" ]]; then
    cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
    SetEnv MAGE_RUN_CODE "${mageRunCode}"
EOF
  fi
  cat <<EOF | sudo tee -a "/etc/apache2/sites-available/${configName}.conf" > /dev/null
    LogLevel warn
    ErrorLog ${webRoot}/log/${configName}-apache-ssl-error.log
    CustomLog ${webRoot}/log/${configName}-apache-ssl-access.log custom
  </VirtualHost>
</IfModule>
EOF
fi

echo "Enabling configuration at: /etc/apache2/sites-enabled/${configName}.conf"
test ! -f "/etc/apache2/sites-enabled/${configName}.conf" && sudo a2ensite "${configName}.conf"

if [[ -n $(which systemctl) ]]; then
  echo "Restarting Apache"
  sudo service apache2 restart
fi

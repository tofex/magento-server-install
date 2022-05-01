#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -p  Redis cache port
  -m  Max memory to use in MB
  -s  Save (yes/no)
  -a  Allow syncing (yes/no)
  -y  Sync alias (reqired if allow syncing = no)
  -i  PSync alias (reqired if allow syncing = no)
  -c  Shutdown command

Example: ${scriptName} -p 6379 -m 2048 -s no -a no -y 12345 -i 98765 -c /usr/local/bin/redis_shutdown
EOF
}

trim()
{
  echo -n "$1" | xargs
}

redisCachePort=
maxMemory=
save=
allowSync=
syncAlias=
psyncAlias=
shutdownCommand=

while getopts hp:m:s:a:y:i:c:? option; do
  case "${option}" in
    h) usage; exit 1;;
    p) redisCachePort=$(trim "$OPTARG");;
    m) maxMemory=$(trim "$OPTARG");;
    s) save=$(trim "$OPTARG");;
    a) allowSync=$(trim "$OPTARG");;
    y) syncAlias=$(trim "$OPTARG");;
    i) psyncAlias=$(trim "$OPTARG");;
    c) shutdownCommand=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${redisCachePort}" ]]; then
  echo "No port specified!"
  exit 1
fi

if [[ -z "${maxMemory}" ]]; then
  echo "No max memory specified!"
  exit 1
fi

if [[ -z "${save}" ]]; then
  echo "No save flag specified!"
  exit 1
fi

if [[ -z "${allowSync}" ]]; then
  echo "No allow sync flag specified!"
  exit 1
fi

if [[ "${allowSync}" == "no" ]]; then
  if [[ -z "${syncAlias}" ]]; then
    echo "No sync alias specified!"
    exit 1
  fi

  if [[ -z "${psyncAlias}" ]]; then
    echo "No psync alias specified!"
    exit 1
  fi
fi

if [[ -z "${shutdownCommand}" ]]; then
  echo "No shutdown command specified!"
  exit 1
fi

echo "Stopping Redis cache service"
sudo service "redis_${redisCachePort}" stop

echo "Creating Redis cache configuration at: /etc/redis/redis_${redisCachePort}.conf"
cat <<EOF | sudo tee "/etc/redis/redis_${redisCachePort}.conf" > /dev/null
activerehashing no
aof-load-truncated yes
aof-rewrite-incremental-fsync yes
appendfilename "appendonly.aof"
appendfsync everysec
appendonly no
auto-aof-rewrite-min-size 64mb
auto-aof-rewrite-percentage 100
bind 0.0.0.0
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit pubsub 32mb 8mb 60
daemonize yes
databases 16
dbfilename ${redisCachePort}.rdb
dir /var/lib/redis/${redisCachePort}
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
hll-sparse-max-bytes 3000
hz 10
latency-monitor-threshold 0
list-max-ziplist-entries 512
list-max-ziplist-value 64
logfile /var/log/redis/${redisCachePort}.log
loglevel notice
lua-time-limit 5000
maxmemory ${maxMemory}MB
maxmemory-policy allkeys-lru
maxmemory-samples 5
notify-keyspace-events ""
no-appendfsync-on-rewrite no
pidfile /var/run/redis_${redisCachePort}.pid
port ${redisCachePort}
rdbchecksum yes
rdbcompression yes
repl-disable-tcp-nodelay no
repl-diskless-sync no
repl-diskless-sync-delay 5
set-max-intset-entries 512
slave-priority 100
slave-serve-stale-data yes
slowlog-log-slower-than 10000
slowlog-max-len 128
stop-writes-on-bgsave-error no
tcp-backlog 511
tcp-keepalive 300
timeout 0
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
EOF

if [[ "${save}" == "yes" ]]; then
  cat <<EOF | sudo tee -a "/etc/redis/redis_${redisCachePort}.conf" > /dev/null
save 900 1
save 300 10
save 60 10000
EOF
fi

if [[ -n "${redisCachePassword}" ]]; then
  cat <<EOF | sudo tee -a "/etc/redis/redis_${redisCachePort}.conf" > /dev/null
requirepass ${redisCachePassword}
EOF
fi

if [[ "${allowSync}" == "no" ]]; then
  cat <<EOF | sudo tee -a "/etc/redis/redis_${redisCachePort}.conf" > /dev/null
rename-command SYNC ${syncAlias}
rename-command PSYNC ${psyncAlias}
EOF
fi

echo "Creating Redis service at: /etc/init.d/redis_${redisCachePort}"
cat <<EOF | sudo tee "/etc/init.d/redis_${redisCachePort}" > /dev/null
#!/bin/sh
### BEGIN INIT INFO
# Provides: redis_${redisCachePort}
# Required-Start: \$network \$local_fs \$remote_fs
# Required-Stop: \$network \$local_fs \$remote_fs
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Should-Start: \$syslog \$named
# Should-Stop: \$syslog \$named
# Short-Description: start and stop redis_${redisCachePort}
# Description: Redis daemon
### END INIT INFO
EXEC=\$(which redis-server)
CLIEXEC=\$(which redis-cli)
PIDFILE="/var/run/redis_${redisCachePort}.pid"
CONF="/etc/redis/redis_${redisCachePort}.conf"
REDISPORT="${redisCachePort}"
case "\$1" in
  start)
    if [ -f \$PIDFILE ]
    then
      echo "\$PIDFILE exists, process is already running or crashed"
    else
      echo "Starting Redis server..."
      \$EXEC \$CONF
    fi
    ;;
  stop)
    if [ ! -f \$PIDFILE ]
    then
      echo "\$PIDFILE does not exist, process is not running"
    else
      PID=\$(cat \$PIDFILE)
      echo "Stopping ..."
      ${shutdownCommand}
      while [ -x /proc/\${PID} ]
      do
        echo "Waiting for Redis to shutdown ..."
        sleep 1
      done
      echo "Redis stopped"
    fi
    ;;
  status)
    PID=\$(cat \$PIDFILE)
    if [ ! -x /proc/\${PID} ]
    then
      echo 'Redis is not running'
    else
      echo "Redis is running (\$PID)"
    fi
    ;;
  restart)
    \$0 stop
    \$0 start
    ;;
  *)
    echo "Please use start, stop, restart or status as first argument"
    ;;
esac
EOF

sudo systemctl daemon-reload

echo "Starting Redis cache service"
sudo service "redis_${redisCachePort}" start

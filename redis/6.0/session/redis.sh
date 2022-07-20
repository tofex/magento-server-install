#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                  Show this message
  --redisSessionPort      Redis session port
  --redisSessionPassword  Redis session password
  --maxMemory             Max memory to use in MB
  --save                  Save (yes/no)
  --allowSync             Allow syncing (yes/no)
  --syncAlias             Sync alias (reqired if allow syncing = no)
  --psyncAlias            PSync alias (reqired if allow syncing = no)
  --shutdownCommand       Shutdown command (optional)

Example: ${scriptName} --redisSessionPort 6379 --maxMemory 256 --save no --allowSync no --syncAlias 12345 --psyncAlias 98765 --shutdownCommand /usr/local/bin/redis_shutdown
EOF
}

redisSessionPort=
redisSessionPassword=
maxMemory=
save=
allowSync=
syncAlias=
psyncAlias=
shutdownCommand=

if [[ -f "${currentPath}/../../../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${redisSessionPort}" ]]; then
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
  if [[ -n "${redisSessionPassword}" ]]; then
    shutdownCommand="\\\$CLIEXEC -p \\\$REDISPORT -a ${redisSessionPassword} --no-auth-warning shutdown"
  else
    shutdownCommand="\\\$CLIEXEC -p \\\$REDISPORT shutdown"
  fi
fi

if [[ ! -f /.dockerenv ]]; then
  echo "Stopping Redis session service"
  sudo service "redis_${redisSessionPort}" stop
fi

echo "Creating Redis session configuration at: /etc/redis/redis_${redisSessionPort}.conf"
cat <<EOF | sudo tee "/etc/redis/redis_${redisSessionPort}.conf" > /dev/null
acllog-max-len 128
activerehashing no
always-show-logo no
aof-load-truncated yes
aof-rewrite-incremental-fsync yes
aof-use-rdb-preamble yes
appendfilename "appendonly.aof"
appendfsync everysec
appendonly no
auto-aof-rewrite-min-size 64mb
auto-aof-rewrite-percentage 100
bind 0.0.0.0
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit pubsub 32mb 8mb 60
client-output-buffer-limit replica 256mb 64mb 60
daemonize yes
databases 16
dbfilename ${redisSessionPort}.rdb
dir /var/lib/redis/${redisSessionPort}
dynamic-hz yes
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
hll-sparse-max-bytes 3000
hz 10
jemalloc-bg-thread yes
latency-monitor-threshold 0
lazyfree-lazy-expire no
lazyfree-lazy-eviction no
lazyfree-lazy-server-del no
lazyfree-lazy-user-del no
list-compress-depth 0
list-max-ziplist-size -2
logfile /var/log/redis/${redisSessionPort}.log
loglevel notice
lua-time-limit 5000
maxmemory ${maxMemory}MB
maxmemory-policy allkeys-lru
maxmemory-samples 5
notify-keyspace-events ""
no-appendfsync-on-rewrite no
pidfile /var/run/redis_${redisSessionPort}.pid
port ${redisSessionPort}
protected-mode no
rdbchecksum yes
rdbcompression yes
rdb-del-sync-files no
rdb-save-incremental-fsync yes
replica-lazy-flush no
replica-priority 100
replica-read-only yes
replica-serve-stale-data yes
repl-disable-tcp-nodelay no
repl-diskless-load disabled
repl-diskless-sync no
repl-diskless-sync-delay 5
set-max-intset-entries 512
slowlog-log-slower-than 10000
slowlog-max-len 128
stop-writes-on-bgsave-error no
stream-node-max-bytes 4096
stream-node-max-entries 100
supervised no
tcp-backlog 511
tcp-keepalive 300
timeout 0
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
EOF

if [[ "${save}" == "yes" ]]; then
  cat <<EOF | sudo tee -a "/etc/redis/redis_${redisSessionPort}.conf" > /dev/null
save 900 1
save 300 10
save 60 10000
EOF
fi

if [[ -n "${redisSessionPassword}" ]]; then
  cat <<EOF | sudo tee -a "/etc/redis/redis_${redisSessionPort}.conf" > /dev/null
requirepass ${redisSessionPassword}
EOF
fi

if [[ "${allowSync}" == "no" ]]; then
  cat <<EOF | sudo tee -a "/etc/redis/redis_${redisSessionPort}.conf" > /dev/null
rename-command SYNC ${syncAlias}
rename-command PSYNC ${psyncAlias}
EOF
fi

if [[ ! -f /.dockerenv ]]; then
  echo "Creating Redis service at: /etc/init.d/redis_${redisSessionPort}"
  cat <<EOF | sudo tee "/etc/init.d/redis_${redisSessionPort}" > /dev/null
#!/bin/sh
### BEGIN INIT INFO
# Provides: redis_${redisSessionPort}
# Required-Start: \$network \$local_fs \$remote_fs
# Required-Stop: \$network \$local_fs \$remote_fs
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Should-Start: \$syslog \$named
# Should-Stop: \$syslog \$named
# Short-Description: start and stop redis_${redisSessionPort}
# Description: Redis daemon
### END INIT INFO
EXEC=\$(which redis-server)
CLIEXEC=\$(which redis-cli)
PIDFILE="/var/run/redis_${redisSessionPort}.pid"
CONF="/etc/redis/redis_${redisSessionPort}.conf"
REDISPORT="${redisSessionPort}"
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

  echo "Starting Redis session service"
  sudo service "redis_${redisSessionPort}" start
fi

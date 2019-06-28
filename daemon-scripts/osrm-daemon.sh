#!/bin/bash
### BEGIN INIT INFO
# Provides:          <NAME>
# Required-Start:    $local_fs $network $named $time $syslog
# Required-Stop:     $local_fs $network $named $time $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       <DESCRIPTION>
### END INIT INFO
# update-rc.d foobar defaults

SCRIPT=/usr/local/bin/osrm-daemon
RUNAS=michal

PIDFILE=/var/run/osrm-daemon.pid
LOGFILE=/var/log/osrm_daemon.log

start() {
  if [ -f /var/run/$PIDFILE ] && kill -0 $(cat /var/run/$PIDFILE); then
    echo 'Service already running' >&2
    return 1
  fi
  echo 'Starting service…' >&2
  touch $LOGFILE; chown $RUNAS $LOGFILE
  local CMD="$SCRIPT &> \"$LOGFILE\" & echo \$!"
  su -c "$CMD" $RUNAS > "$PIDFILE"
  echo 'Service started' >&2
}

stop() {
  #if [ ! -f "$PIDFILE" ] || ! kill -0 $(cat "$PIDFILE"); then
  #  echo 'Service not running' >&2
  #  return 1
  #fi
  echo 'Stopping service…' >&2
  pkill -f osrm-daemon
  sleep 4s
  /usr/bin/pkill -f osrm-routed
  rm -f "$PIDFILE"
  kill -15 $(cat "$PIDFILE") && rm -f "$PIDFILE"
  echo 'Service stopped' >&2
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  reload)
	kill `ps ax |grep osrm-routed| grep -v grep | sed 's/? .*//'`
	;;
  restart)
    stop
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|reload}"
esac

#!/bin/sh
### BEGIN INIT INFO
# Provides:          mackerel-agent
# Short-Description: 'mackerel.io agent'
# Description:       'mackerel.io agent'
### END INIT INFO

NAME=mackerel-agent                  # Introduce the short server's name here

ETC=$(dirname $0)/..
[ -r $ETC/default/$NAME ] && . $ETC/default/$NAME

PATH=/sbin:/usr/sbin:/bin:/usr/bin
DAEMON=${DAEMON:="/usr/bin/$NAME"}
SCRIPTNAME=$ETC/init.d/$NAME.sh
LOGFILE=${LOGILE:="/var/log/$NAME.log"}
PIDFILE=${PIDFILE:="/var/run/$NAME.pid"}
ROOT=${ROOT:="/var/lib/$NAME"}

# Exit if the package is not installed
[ -x $DAEMON ] || exit 0

#
# Function that starts the daemon/service
#
do_start()
{
    $DAEMON ${APIBASE:+--apibase=$APIBASE} ${APIKEY:+--apikey=$APIKEY} --pidfile=$PIDFILE --root=$ROOT $OTHER_OPTS >>$LOGFILE 2>&1 &
    sleep 3
    kill -0 $(cat $PIDFILE 2>/dev/null) >/dev/null 2>&1
    return $?
}

do_configtest()
{
    $DAEMON configtest ${APIBASE:+--apibase=$APIBASE} ${APIKEY:+--apikey=$APIKEY} --pidfile=$PIDFILE --root=$ROOT $OTHER_OPTS >>$LOGFILE 2>&1
    return $?
}

do_retire()
{
    $DAEMON retire -force ${APIBASE:+--apibase=$APIBASE} ${APIKEY:+--apikey=$APIKEY} --root=$ROOT $OTHER_OPTS >>$LOGFILE 2>&1
}

#
# Function that stops the daemon/service
#
do_stop()
{
    # TODO support timeout
    kill -15 $(cat $PIDFILE 2>/dev/null)
    RETVAL="$?"
    [ "$RETVAL" = 2 ] && return 2
    # XXX original init script kills all running mackerel-agent here
    # Many daemons don't delete their pidfiles when they exit.
    rm -f $PIDFILE
    return "$RETVAL"
}

case "$1" in
    start)
        echo "Starting $NAME..."
        do_start
        retval=$?
        case "$retval" in
            0) echo 'success' ;;
            *) echo 'failed'; exit $retval ;;
        esac
        ;;
    stop)
        echo "Stopping $NAME"
        do_stop
        retval=$?
        if [ "$AUTO_RETIREMENT" != "" ] && [ "$AUTO_RETIREMENT" != "0" ]; then
          do_retire || retval=$?
        fi
        case "$retval" in
            0|1) echo 'success' ;;
            *) echo 'failed'; exit $retval ;;
        esac
        ;;
    status)
        ps | grep ^$(cat $PIDFILE) &>/dev/null
        retval=$?
        case "$retval" in
            0) echo "$NAME is running" ;;
            *) echo "$NAME is stopped"; exit 1 ;;
        esac
        ;;
    reload|force-reload)
        do_configtest || exit $?
        echo "Reloading $NAME ... "
        do_stop
        retval=$?
        case "$retval" in
            0|1)
                do_start
                retval=$?
                case "$retval" in
                    0) echo "success" ;;
                    *) echo "failed"; exit $retval ;; # Failed to start
                esac
                ;;
            *)
                # Failed to stop
                echo "failed"; exit $retval
            ;;
        esac
        ;;
    restart)
        echo "Restarting $NAME ... "
        do_stop
        retval=$?
        case "$retval" in
            0|1)
                do_start
                retval=$?
                case "$retval" in
                    0) echo "success" ;;
                    *) echo "failed"; exit $retval ;; # Failed to start
                esac
                ;;
            *)
                # Failed to stop
                echo "failed"; exit $retval
            ;;
        esac
        ;;
    configtest)
        do_configtest
        retval=$?
        case "$retval" in
            0) echo "success" ;;
            *) echo "failed"; exit $retval ;; # Failed to start
        esac
        ;;
    *)
        echo "Usage: $SCRIPTNAME {start|stop|restart|reload|status|configtest}" >&2
        exit 3
    ;;
esac

:

#!/bin/sh
#
# tv.js initscript
#
### BEGIN INIT INFO
# Provides:          tv.js
# Required-Start:    $local_fs $syslog
# Required-Stop:     $local_fs $syslog
# Default-Start:     S
# Default-Stop:      0 1 6
# Short-Description: Apple-Like TV for Torrent Streaming in JS
# Description:       A Smart TV application to stream movies using BitTorrent.
#                    (Yes it actually streams them in order even though it's BitTorrent)
#                    Tv.js used iTunes' API to find movies, isoHunt to search
#                    torrents and BitTorrent to downloading/stream movies.
#                    It runs as a server which can run on a Raspberry Pi and
#                    the UI can be controlled from a smartphone (no need of keyboard or mouse).
### END INIT INFO

USER=pi
TVJS_REPO=https://github.com/SamyPesse/tv.js.git
TVJS_DIR="/home/${USER}/tv.js"
OUT="/home/${USER}/tvjs.log"
NODE=$(which node)
CHROMIUM=$(which chromium)

. /lib/lsb/init-functions

case "$1" in
update)
        echo "updating tv.js from $TVJS_REPO"
        su - $USER
        rm -rf $TVJS_DIR
        mkdir $TVJS_DIR
        git clone $TVJS_REPO $TVJS_DIRw
        cd $TVJS_DIR
        make install > $OUT 2>$OUT &
        make build > $OUT 2>$OUT &
        ;;

start)
        log_daemon_msg "starting tv.js:" "tv.js" || true
        if start-stop-daemon --background --start --quiet --oknodo --make-pidfile --pidfile $TVJS_DIR/tvjs.pid --exec $NODE -- $TVJS_DIR/bin/run.js;  then
            export DISPLAY=:0.0
            echo "opening chromium on tv.js"
            start-stop-daemon --background --start --quiet --oknodo --make-pidfile --pidfile $TVJS_DIR/chromium.pid --exec $CHROMIUM -- --kiosk http://localhost:8888;
            log_end_msg 0 || true
        else
            log_end_msg 1 || true
        fi
        ;;

stop)
        log_daemon_msg "Stopping tv.js:" "tv.js" || true
        start-stop-daemon --stop --quiet --oknodo --retry 30 --pidfile $TVJS_DIR/chromium.pid
        if start-stop-daemon --stop --quiet --oknodo --pidfile $TVJS_DIR/tvjs.pid; then
            log_end_msg 0 || true
        else
            log_end_msg 1 || true
        fi
        ;;

restart)
        log_daemon_msg "Restarting tv.js:" "tv.js" || true
        start-stop-daemon --stop --quiet --oknodo --retry 30 --pidfile $TVJS_DIR/tvjs.pid
        start-stop-daemon --stop --quiet --oknodo --retry 30 --pidfile $TVJS_DIR/chromium.pid
        check_for_no_start log_end_msg
        check_dev_null log_end_msg
        if start-stop-daemon --background --start --quiet --oknodo --make-pidfile --pidfile $TVJS_DIR/tvjs.pid --exec $NODE -- $TVJS_DIR/bin/run.js; then
                export DISPLAY=:0.0
                echo "opening chromium on tv.js"
                start-stop-daemon --background --start --quiet --oknodo --make-pidfile --pidfile $TVJS_DIR/chromium.pid --exec $CHROMIUM -- --kiosk http://localhost:8888;
                log_end_msg 0 || true
        else
            log_end_msg 1 || true
        fi
        ;;


*)
        echo "usage: $0 (start|stop|restart|update)"
esac

exit 0

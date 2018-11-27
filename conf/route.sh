#!/bin/sh

start(){
        echo "start nginx......"
	/usr/local/openresty/nginx/sbin/nginx -p /usr/local/openresty -c /usr/local/openresty/routing/conf/nginx.conf
}

quit(){
        echo "quit nginx......"
        /usr/local/openresty/nginx/sbin/nginx -p /usr/local/openresty -c /usr/local/openresty/routing/conf/nginx.conf -s quit
}

stop(){
       echo "stop nginx......"
       /usr/local/openresty/nginx/sbin/nginx -p /usr/local/openresty -c /usr/local/openresty/routing/conf/nginx.conf -s stop
}

reload(){
       echo "reload nginx......"
       /usr/local/openresty/nginx/sbin/nginx -p /usr/local/openresty -c /usr/local/openresty/routing/conf/nginx.conf -s reload
}


case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    reload)
        reload
        ;;
    quit)
        quit
        ;;
    restart)
        stop
        start
        ;;
    *)
        printf 'Usage: %s {start|stop|reload|quit|restart}\n' "$prog"
        exit 1
        ;;
esac


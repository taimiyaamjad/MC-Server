#!/usr/bin/env bash
# ============================================================
#  Start / restart the NPanel nginx reverse proxy
#  By Team Zen Development — https://www.zendevelopment.in
#
#  Usage:  bash start-proxy.sh
#  Fixes:  CSS not loading + login redirect behind /proxy/4567/
# ============================================================

NPANEL_PORT="${NPANEL_PORT:-4567}"
PROXY_PORT="${PROXY_PORT:-7860}"
CONF="/tmp/npanel_nginx.conf"

echo "[*] Stopping any existing nginx..."
pkill nginx 2>/dev/null || true
sleep 1

# Check NPanel is actually running
if ! ss -tlnp 2>/dev/null | grep -q ":$NPANEL_PORT" && \
   ! netstat -tlnp 2>/dev/null | grep -q ":$NPANEL_PORT"; then
    echo "[WARN] NPanel doesn't appear to be running on port $NPANEL_PORT"
    echo "       Start your MC server first: cd /opt/minecraft && ./mc.sh start"
fi

echo "[*] Writing nginx config..."
cat > "$CONF" << NGINXEOF
worker_processes 1;
error_log /tmp/nginx_error.log warn;
pid /tmp/nginx.pid;
events { worker_connections 64; }
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen $PROXY_PORT;
        server_name _;

        location /proxy/$NPANEL_PORT/ {
            rewrite ^/proxy/$NPANEL_PORT/(.*)$ /\$1 break;
            proxy_pass http://127.0.0.1:$NPANEL_PORT;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host 127.0.0.1:$NPANEL_PORT;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_read_timeout 86400;
            proxy_redirect ~^http://[^/]+/(.*)\$ /proxy/$NPANEL_PORT/\$1;
            sub_filter_once off;
            sub_filter_types text/html text/css application/javascript;
            sub_filter 'href="/'  'href="/proxy/$NPANEL_PORT/';
            sub_filter "href='/"  "href='/proxy/$NPANEL_PORT/";
            sub_filter 'src="/'   'src="/proxy/$NPANEL_PORT/';
            sub_filter "src='/"   "src='/proxy/$NPANEL_PORT/";
            sub_filter 'action="/' 'action="/proxy/$NPANEL_PORT/';
            sub_filter 'url(/'    'url(/proxy/$NPANEL_PORT/';
        }

        location = / {
            return 301 /proxy/$NPANEL_PORT/;
        }

        location / {
            proxy_pass http://127.0.0.1:$NPANEL_PORT;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host 127.0.0.1:$NPANEL_PORT;
            proxy_read_timeout 86400;
            proxy_redirect ~^http://[^/]+/(.*)\$ /proxy/$NPANEL_PORT/\$1;
            sub_filter_once off;
            sub_filter_types text/html text/css application/javascript;
            sub_filter 'href="/'  'href="/proxy/$NPANEL_PORT/';
            sub_filter "href='/"  "href='/proxy/$NPANEL_PORT/";
            sub_filter 'src="/'   'src="/proxy/$NPANEL_PORT/';
            sub_filter "src='/"   "src='/proxy/$NPANEL_PORT/";
            sub_filter 'action="/' 'action="/proxy/$NPANEL_PORT/';
            sub_filter 'url(/'    'url(/proxy/$NPANEL_PORT/';
        }
    }
}
NGINXEOF

echo "[*] Starting nginx on port $PROXY_PORT → NPanel on port $NPANEL_PORT..."
if nginx -t -c "$CONF" 2>/dev/null && nginx -c "$CONF"; then
    echo ""
    echo "✅ Proxy running!"
    echo "   Open: https://YOUR-SANDBOX-DOMAIN/proxy/$NPANEL_PORT/"
    echo "   CSS and login redirects should now work correctly."
else
    echo "[ERR] nginx failed. Error log:"
    cat /tmp/nginx_error.log 2>/dev/null || true
fi

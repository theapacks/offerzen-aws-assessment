#!/bin/sh

cat > /usr/share/nginx/html/config.js <<EOF
window.SERVER_URL = "${SERVER_URL:-http://localhost:3011}";
EOF

exec "$@"

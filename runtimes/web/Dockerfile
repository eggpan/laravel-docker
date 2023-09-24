FROM nginx:1.25-alpine-slim

COPY <<'EOF' /etc/nginx/conf.d/default.conf
server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;

    location / {
        root   /var/www/static-data;
        try_files $uri @unit;
    }

    location @unit {
        proxy_pass   http://php;
        proxy_set_header Host $host;
    }

    location ~ /\.ht {
        deny  all;
    }
}
EOF

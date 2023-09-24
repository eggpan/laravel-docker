ARG PHP_VERSION

FROM alpine:3.15 as php7.4-builder
FROM alpine:3.16 as php8.0-builder
FROM alpine:3.18 as php8.1-builder
FROM alpine:3.18 as php8.2-builder


FROM php${PHP_VERSION}-builder as main
ARG PHP_VERSION
RUN if [ "$PHP_VERSION" = "8.2" ]; then \
      PACKAGE_VERSION="82"; \
    elif [ "$PHP_VERSION" = "8.1" ]; then \
      PACKAGE_VERSION="81"; \
    elif [ "$PHP_VERSION" = "8.0" ]; then \
      PACKAGE_VERSION="8"; \
    elif [ "$PHP_VERSION" = "7.4" ]; then \
      PACKAGE_VERSION="7"; \
    fi; \
    apk add --no-cache \
        bash \
        curl \
        doas \
        "php${PACKAGE_VERSION}" \
        "php${PACKAGE_VERSION}-bcmath" \
        "php${PACKAGE_VERSION}-common" \
        "php${PACKAGE_VERSION}-curl" \
        "php${PACKAGE_VERSION}-dom" \
        "php${PACKAGE_VERSION}-fileinfo" \
        "php${PACKAGE_VERSION}-iconv" \
        "php${PACKAGE_VERSION}-json" \
        "php${PACKAGE_VERSION}-mbstring" \
        "php${PACKAGE_VERSION}-mysqlnd" \
        "php${PACKAGE_VERSION}-opcache" \
        "php${PACKAGE_VERSION}-openssl" \
        "php${PACKAGE_VERSION}-pdo" \
        "php${PACKAGE_VERSION}-pdo_mysql" \
        "php${PACKAGE_VERSION}-pecl-igbinary" \
        "php${PACKAGE_VERSION}-pecl-msgpack" \
        "php${PACKAGE_VERSION}-pecl-xdebug" \
        "php${PACKAGE_VERSION}-phar" \
        "php${PACKAGE_VERSION}-tokenizer" \
        "php${PACKAGE_VERSION}-xml" \
        "php${PACKAGE_VERSION}-xmlreader" \
        "php${PACKAGE_VERSION}-xmlwriter" \
        "php${PACKAGE_VERSION}-zip" \
        shadow \
        tzdata \
        "unit-php${PACKAGE_VERSION}" \
        unzip && \
    if [ ! -e /usr/bin/php ]; then ln -s "php${PACKAGE_VERSION}" /usr/bin/php; fi && \
    curl -so /usr/local/bin/composer https://getcomposer.org/download/latest-stable/composer.phar && \
    chmod +x /usr/local/bin/composer && \
    adduser -D -s /bin/bash user && \
    mkdir -p /laravel/public && \
    chown user:user -R /laravel && \
    echo "permit nopass user" >> /etc/doas.d/doas.conf

COPY <<'EOF' /usr/local/etc/unit/config.json
{
  "listeners": {
    "*:80": {
      "pass": "routes"
    }
  },

  "routes": [
    {
      "match": {
        "uri": "!/index.php"
      },
      "action": {
        "share": "/laravel/public$uri",
        "fallback": {
          "pass": "applications/laravel"
        }
      }
    }
  ],

  "applications": {
    "laravel": {
      "type": "php",
      "root": "/laravel/public/",
      "script": "index.php"
    }
  }
}
EOF

COPY --chmod=755 <<EOF /usr/local/bin/entrypoint.sh
#!/bin/sh
doas unitd
for i in {1..30}; do
  [ -f /run/unit.pid ] && break
  sleep 0.1
done

doas curl -s -X PUT -d @/usr/local/etc/unit/config.json --unix-socket /run/control.unit.sock  http://localhost/config

doas kill -TERM $(cat /run/unit.pid)
for i in {1..30}; do
  [ ! -f /run/unit.pid ] && break
  sleep 0.1
done
exec doas unitd --no-daemon
EOF


COPY --chmod=755 <<"EOF" /usr/local/bin/setup.sh
#!/bin/bash -eu
doas apk add --no-cache git

# Execute as root because doas cannot be executed if the UID changes during the process.
doas bash -c "
  groupmod -g $GROUP_ID user;
  usermod -u $USER_ID user;
  chown -R user:user /home/user
  chown user:user .
  su user -c \"/usr/local/bin/composer create-project --prefer-dist laravel/laravel:${LARAVEL_VERSION} .\"
    find ./storage/* ./bootstrap/cache -type d | xargs chmod 777
    cp -ar . /tmp/work
  "
EOF

ENV USER_ID=1000
ENV GROUP_ID=1000

USER user
CMD ["entrypoint.sh"]

# DockerLamp

Base image for running PHP applications on Apache — built for Symfony, Sylius and Magento.

One branch (and one tag) per PHP version. This is `PHP8.5`.

## What's in the image

- **PHP 8.5** on Apache (`php:8.5-apache`, Debian 13)
  - Extensions: `bcmath` `bz2` `calendar` `exif` `ftp` `gd` `intl` `mysqli` `pdo_mysql`
    `pdo_pgsql` `pgsql` `soap` `xsl` `zip`, plus everything the official image already
    bundles (`curl` `dom` `mbstring` `opcache` `simplexml` `xml` …)
  - `gd` built with **JPEG, WebP and FreeType** support
  - PECL: `amqp` `imagick` `mongodb` `redis` — all pinned
  - OPcache tuned for large frameworks, **JIT enabled** (`tracing`)
- **Composer 2**
- **Node.js 24** with **corepack** (`yarn` and `pnpm` available)
- `git`, `unzip`, `zip`
- `mod_rewrite`, `mod_headers` and `mod_expires` enabled

The image ships **production** PHP defaults and no debugger — see
[Development setup](#development-setup) below.

## Usage

```yml
services:
  web:
    build:
      context: .
      dockerfile: docker/Dockerfile
      args:
        USER_ID: ${USER_ID}
        GROUP_ID: ${GROUP_ID}
    ports:
      - "8081:80"
    environment:
      APP_ENV: dev
      PHP_IDE_CONFIG: "serverName=Backend"
    volumes:
      - ./:/var/www/html
      - ./ssh:/var/www/.ssh
    container_name: ${PROJECT_NAME}_web
  database:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: ${DB_NAME}
    volumes:
      - db_data:/var/lib/mysql
    ports:
      - "3320:3306"
    container_name: ${PROJECT_NAME}_db
volumes:
  db_data: null
```

```
PROJECT_NAME=project
DB_NAME=project
USER_ID=1000
GROUP_ID=1000
```

## Document root

`APACHE_DOCUMENT_ROOT` defaults to `/var/www/html/public` (Symfony / Sylius). For Magento,
point it at `pub/` — no rebuild needed:

```yml
services:
  web:
    environment:
      APACHE_DOCUMENT_ROOT: /var/www/html/pub
```

## Development setup

Two things are deliberately left to the project image: **the debugger** and **development
PHP settings**.

> **Heads up:** the base image sets `opcache.validate_timestamps=0`. That is right for
> production, but in a dev container with your code mounted as a volume **your edits will
> not be picked up** until you enable `dev.ini` below.

```dockerfile
FROM rrcfesc/lamp:8.5

ARG USER_ID
ARG GROUP_ID

RUN pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && rm -rf /tmp/pear

COPY dev.ini    /usr/local/etc/php/conf.d/zzz-dev.ini
COPY xdebug.ini /usr/local/etc/php/conf.d/zzz-xdebug.ini

RUN usermod --non-unique --uid ${USER_ID} www-data \
    && groupmod --non-unique --gid ${GROUP_ID} www-data \
    && chown www-data:www-data /var/www
```

`dev.ini` — a ready-made copy lives in [`extraFiles/dev.ini`](extraFiles/dev.ini):

```ini
display_errors = On
display_startup_errors = On
error_reporting = E_ALL
opcache.validate_timestamps = 1
opcache.revalidate_freq = 0
opcache.jit = disable
```

`xdebug.ini` — note these are **Xdebug 3** settings; the old `remote_*` options are Xdebug 2
and do nothing here:

```ini
xdebug.mode = debug,develop
xdebug.client_host = host.docker.internal
xdebug.client_port = 9003
xdebug.start_with_request = yes
xdebug.idekey = PHPSTORM
```

Point your IDE at port **9003** (Xdebug 3's default, not 9000). Loading Xdebug disables the
JIT automatically — that is expected.

## Compiling other extensions

The image keeps no build toolchain, but the underlying `php:8.5-apache` provides `gcc`,
`make`, `autoconf`, `phpize` and the PHP headers, so PECL extensions still build on top:

```dockerfile
RUN pecl install <extension> && docker-php-ext-enable <extension>
```

Extensions that link against a system library need its `-dev` package first, e.g.
`apt-get install -y --no-install-recommends libssh2-1-dev` before `pecl install ssh2`.

## Overriding PHP settings

Anything in `/usr/local/etc/php/conf.d/` wins if it sorts after `zz-lamp.ini`:

```dockerfile
COPY my-overrides.ini /usr/local/etc/php/conf.d/zzz-my-overrides.ini
```

## License

MIT — see [LICENSE](LICENSE).

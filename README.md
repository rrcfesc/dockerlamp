# About

This image supports the instalation of Magento and Sylius


## What does provide this image?

Provide a easy way to test your application over PHP8 and NodeJs

- PHP 7.4
    - Composer 2
    - RabbitMQ
    - MongoDb

- Node 16

# How to use

```yml
version: '3.8'
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
    expose:
      - "9000"
    environment:
      APP_ENV: dev
      PHP_XDEBUG_ENABLED: 1
      XDEBUG_CONFIG: remote_host=host.docker.internal
      PHP_IDE_CONFIG: "serverName=Backend"
    volumes:
      - ./:/var/www/html
      - ./ssh:/var/www/.ssh
    container_name: ${PROJECT_NAME}_web
  database:
    image: mysql:8
    command: --default-authentication-plugin=mysql_native_password
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: ${DB_NAME}
    volumes:
      - unitec_forms:/var/lib/mysql
    ports:
      - "3320:3306"
    container_name: ${PROJECT_NAME}_db
volumes:
  unitec_forms: null
```

```Dockerfile
FROM rrcfesc/lamp:8.0

LABEL maintainer="rrcfesc@gmail.com"

ENV IDEKEY "PHPSTORM"
ENV REMOTEPORT "9000"
ARG USER_ID
ARG GROUP_ID

RUN pecl install xdebug-2.9.1 \
    && docker-php-ext-enable xdebug \
    && echo "xdebug.idekey = ${IDEKEY}" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_port = ${REMOTEPORT}" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_enable = on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_autostart = on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_handler = dbgp" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.profiler_output_dir = '/var/www/html'" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.profiler_enable_trigger = 1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.collect_params = 4" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.collect_vars = on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.dump_globals = on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.dump.SERVER = REQUEST_URI" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.show_local_vars = on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.cli_color = 1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && chmod 666 /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN usermod --non-unique --uid ${USER_ID} www-data \
    && groupmod --non-unique --gid ${GROUP_ID} www-data

RUN chown www-data:www-data /var/www

EXPOSE 80 443
```


```
PROJECT_NAME=project
DB_NAME=project
USER_ID=1000
GROUP_ID=1000
```
FROM php:8.1-apache

LABEL maintainer="rrcfesc@gmail.com"

ARG DEBIAN_FRONTEND=noninteractive \
    TZ=America/Mexico_City

RUN apt-get update
RUN apt-get install -y --no-install-recommends locales curl wget apt-utils tcl build-essential gnupg2 gnupg -y
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh && chmod +x nodesource_setup.sh && ./nodesource_setup.sh && rm nodesource_setup.sh
RUN set -x; \
    locale-gen en_US.UTF-8 && \
    update-locale && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
RUN update-locale LANG=en_US.UTF-8
RUN echo "export LANG=en_US.UTF-8\nexport LANGUAGE=en_US.UTF-8\nexport LC_ALL=en_US.UTF-8\nexport PYTHONIOENCODING=UTF-8" | tee -a /etc/bash.bashrc
RUN apt-get install libmcrypt-dev libmagickwand-dev librabbitmq-dev \
    gcc g++ make libcurl3-openssl-dev\
    libbz2-dev libicu-dev libxml2-dev libxslt1-dev \
    telnet zip libonig-dev\
    zlib1g-dev libzip-dev \
    unzip vim curl libssl-dev libcurl4-openssl-dev \
    libldap2-dev \
    libfreetype6-dev libwebp-dev libgmp-dev libjpeg62-turbo-dev libpng-dev libgd-dev \
    libtidy-dev \
    libxslt-dev \
    libxpm-dev \
    libpq-dev \
    telnet nmap net-tools inetutils-ping default-mysql-client\
    pkg-config sshpass nodejs yarn  -y
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --2
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions amqp intl json
RUN docker-php-ext-install -j$(nproc) zip gd
RUN docker-php-ext-configure hash --with-mhash
RUN docker-php-ext-install -j$(nproc) bcmath bz2 calendar curl dom ftp exif mbstring mysqli opcache \
        pdo pdo_mysql pgsql pdo_pgsql simplexml soap xml xsl
RUN pecl install mongodb && docker-php-ext-enable mongodb

COPY extraFiles/000-default.conf /etc/apache2/sites-available/000-default.conf
ADD extraFiles/php.ini /usr/local/etc/php

WORKDIR /var/www/html

EXPOSE 80 443

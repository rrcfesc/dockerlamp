FROM php:7.3-apache

LABEL maintainer="rrcfesc@gmail.com"

ENV SERVER_NAME "localhost"
ENV WEBSERVER_USER "www-data"
ENV RIOXYGEN_USER "rioxygen"
ENV IDEKEY "PHPSTORM"
ENV REMOTEPORT "9000"

RUN groupadd rioxygenGroup -g 3000
RUN useradd -g 3000 -m -d /home/${RIOXYGEN_USER} -s /bin/bash ${RIOXYGEN_USER} && usermod -g www-data ${RIOXYGEN_USER} 
RUN mkdir /home/$RIOXYGEN_USER/.ssh
RUN passwd ${RIOXYGEN_USER} -d
RUN groups ${RIOXYGEN_USER}

RUN apt-get update && apt-get install -y --no-install-recommends locales wget apt-utils tcl build-essential -y
RUN set -x; \
    locale-gen es_MX.UTF-8 && \
    update-locale && \
    echo 'LANG="es_MX.UTF-8"' > /etc/default/locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen en_US.UTF-8
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
RUN update-locale LANG=en_US.UTF-8
RUN echo "export LANG=en_US.UTF-8\nexport LANGUAGE=en_US.UTF-8\nexport LC_ALL=en_US.UTF-8\nexport PYTHONIOENCODING=UTF-8" | tee -a /etc/bash.bashrc
RUN apt-get install libzip-dev libmcrypt-dev libmagickwand-dev python-pip gcc g++ make librabbitmq-dev \
    libbz2-dev libicu-dev libxml2-dev libxslt1-dev libfreetype6-dev \
    git unzip vim openssh-server ocaml expect curl libssl-dev libcurl4-openssl-dev \
    libgd-dev \
    libfreetype6-dev \
    libldap2-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libtidy-dev \
    libxslt-dev \    
    pkg-config -y
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure hash --with-mhash \
    && docker-php-ext-install \
    bcmath bz2 calendar curl dom hash
RUN docker-php-ext-install ftp gd intl
RUN docker-php-ext-install json mbstring mysqli opcache pdo pdo_mysql 
RUN docker-php-ext-install simplexml soap wddx xml xsl zip
RUN pecl install amqp && pecl install mongodb && pecl install imagick && docker-php-ext-enable amqp && docker-php-ext-enable mongodb && docker-php-ext-enable imagick
RUN pecl install xdebug-2.7.2 && docker-php-ext-enable xdebug \
    && echo "xdebug.idekey = ${IDEKEY}" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_port = ${REMOTEPORT}" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_enable = on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_autostart = on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_connect_back = off" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_handler = dbgp" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.profiler_output_dir = '/var/www/html'" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.collect_params = 4" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.collect_vars = on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.dump_globals = on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.dump.SERVER = REQUEST_URI" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.show_local_vars = on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.cli_color = 1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && chmod 666 /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN apt-get install gnupg2 gnupg -y
RUN apt-get install net-tools openssh-server supervisor nano vim -y && apt-get install -y apache2 \
    && a2enmod rewrite \
    && a2enmod proxy \
    && a2enmod proxy_fcgi\
    && a2enmod ssl
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN rm /etc/apache2/sites-available/000-default.conf
ADD extraFiles/000-default.conf /etc/apache2/sites-available/000-default.conf
RUN curl http://browscap.org/stream?q=Full_PHP_BrowsCapINI >> "/usr/local/etc/php/browscap.ini"
ADD extraFiles/php.ini /usr/local/etc/php
RUN curl -sL https://deb.nodesource.com/setup_12.x -o nodesource_setup.sh
RUN chmod +x nodesource_setup.sh && ./nodesource_setup.sh
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get install sshpass nodejs yarn -y
RUN npm install -g sass less grunt
ADD extraFiles/entrypoint.sh /usr/local/bin/entrypoint.sh
ADD extraFiles/supervisor.conf /etc/supervisord.conf
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN python2 -m pip install supervisor
RUN mkdir /ssl
RUN openssl req -new -x509 -days 365 -keyout /ssl/privkey.pem -out /ssl/cert.pem -nodes -subj  '/O=VirtualHost Website Company name/OU=Virtual Host Website department/CN=backend.local.com'
RUN groupmod -g $(id -u  ${RIOXYGEN_USER}) www-data

WORKDIR /var/www/html

EXPOSE 80 443

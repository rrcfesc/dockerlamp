# syntax=docker/dockerfile:1
FROM php:8.4-apache

LABEL maintainer="rrcfesc@gmail.com" \
      org.opencontainers.image.source="https://github.com/rrcfesc/dockerlamp" \
      org.opencontainers.image.description="LAMP base image for PHP 8.4 (Symfony / Sylius / Magento)" \
      org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    APACHE_DOCUMENT_ROOT=/var/www/html/public \
    COMPOSER_ALLOW_SUPERUSER=1 \
    NODE_MAJOR=24 \
    PECL_AMQP=2.2.0 \
    PECL_MONGODB=2.4.1 \
    PECL_REDIS=6.3.0 \
    PECL_IMAGICK=3.8.1

# 1) Minimal OS layer: locale, timezone and the few tools Composer really needs.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        locales \
        unzip \
        zip; \
    sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen; \
    locale-gen; \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime; \
    echo "$TZ" > /etc/timezone; \
    rm -rf /var/lib/apt/lists/*

# 2) Node.js + corepack. corepack ships yarn/pnpm, so no third-party apt repo
#    or GPG key is needed for yarn. gnupg is only required to set up the
#    NodeSource repo, so it is purged again right after (apt keeps verifying
#    the repo with gpgv, which is part of apt itself).
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends gnupg; \
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -; \
    apt-get install -y --no-install-recommends nodejs; \
    corepack enable; \
    npm cache clean --force; \
    apt-get purge -y --auto-remove gnupg; \
    rm -rf /var/lib/apt/lists/* /root/.npm

# 3) Composer, straight from the official image.
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# 4) PHP extensions. Build headers are installed, used and purged inside the
#    same layer; ldd then tells us which runtime libraries the freshly built
#    .so files actually need, so only those survive. Same approach the official
#    php images use.
RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libbz2-dev \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libmagickwand-dev \
        libpng-dev \
        libpq-dev \
        librabbitmq-dev \
        libsasl2-dev \
        libssl-dev \
        libwebp-dev \
        libxml2-dev \
        libxslt1-dev \
        libzip-dev; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j"$(nproc)" \
        bcmath \
        bz2 \
        calendar \
        exif \
        ftp \
        gd \
        intl \
        mysqli \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        soap \
        xsl \
        zip; \
    pecl install \
        "amqp-${PECL_AMQP}" \
        "mongodb-${PECL_MONGODB}" \
        "redis-${PECL_REDIS}" \
        "imagick-${PECL_IMAGICK}"; \
    docker-php-ext-enable amqp mongodb redis imagick; \
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark > /dev/null; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) next; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
        | sort -u \
        | xargs -r dpkg-query --search 2>/dev/null \
        | cut -d: -f1 \
        | sort -u \
        | xargs -r apt-mark manual; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/* /tmp/pear; \
    php -m

# 5) Apache modules and vhost. mod_rewrite is what .htaccess needs; without it
#    every RewriteRule fails silently.
RUN a2enmod rewrite headers expires

COPY extraFiles/000-default.conf /etc/apache2/sites-available/000-default.conf

# 6) Production php.ini as the baseline, with our overrides layered in conf.d
#    so the official defaults still apply underneath.
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY extraFiles/zz-lamp.ini "$PHP_INI_DIR/conf.d/zz-lamp.ini"

WORKDIR /var/www/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/ | grep -qE '^[2345]' || exit 1

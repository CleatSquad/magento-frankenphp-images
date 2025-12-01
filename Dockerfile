#syntax=docker/dockerfile:1.20
# Dockerfile for Magento FrankenPHP
# Supports base and dev build targets via BUILD_TYPE ARG
#
# Build examples:
#   docker build --build-arg BUILD_TYPE=base -t magento-frankenphp:base .
#   docker build --build-arg BUILD_TYPE=dev -t magento-frankenphp:dev .

ARG PHP_VERSION=8.4
ARG FRANKENPHP_VERSION=1.10.1
ARG BUILD_TYPE=base

FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-php${PHP_VERSION} AS base
LABEL maintainer="Mohamed El Mrabet <contact@cleatsquad.dev>"

# Combine package installation and cleanup in a single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      cron \
      libfreetype6-dev \
      libicu-dev \
      libjpeg62-turbo-dev \
      libpng-dev \
      libwebp-dev \
      libxslt1-dev \
      zip \
      acl \
      libnss3-tools \
      curl \
      unzip \
      default-mysql-client \
      gosu \
      gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Note: gettext-base provides envsubst used in entrypoint scripts for Xdebug config

# Install PHP extensions in one step
RUN set -eux; \
    install-php-extensions \
      bcmath \
      gd \
      intl \
      mbstring \
      opcache \
      pdo_mysql \
      soap \
      xsl \
      zip \
      sockets \
      ftp \
      sodium \
      redis \
      apcu \
    && true

# Copy composer from official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set up app dir and ownership
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data \
    && mkdir -p /etc/caddy /data/caddy /var/www/html /var/www/.composer /etc/php \
    && chown -R www-data:www-data /var/www /data /etc/caddy \
    && chown root:root /etc/php

# Copy configuration files and entrypoint
COPY --chown=www-data:www-data common/Caddyfile.template /etc/caddy/Caddyfile.template
COPY --chmod=755 common/entrypoint-base.sh /usr/local/bin/entrypoint.sh
COPY common/conf/app.ini /usr/local/etc/php/conf.d/zz-app.ini
COPY common/conf/opcache.ini /usr/local/etc/php/conf.d/zz-opcache.ini

ENV CADDY_LOG_OUTPUT=stdout \
    COMPOSER_ALLOW_SUPERUSER=0 \
    COMPOSER_HOME=/var/www/.composer

WORKDIR /var/www/html

EXPOSE 80 443 443/udp 2019

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Optional healthcheck
HEALTHCHECK --interval=30s --timeout=5s CMD curl -f http://localhost/ || exit 1

FROM base AS dev

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    mkcert \
 && apt-get clean && rm -rf /var/lib/apt/lists/* \
 && install-php-extensions xdebug \
 && curl -L -o /usr/local/bin/mhsendmail \
    https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64 \
 && chmod +x /usr/local/bin/mhsendmail

# Copy PHP dev configuration from common
COPY common/conf/mail.ini /usr/local/etc/php/conf.d/zz-mail.ini
COPY common/conf/xdebug.ini /usr/local/etc/php/conf.d/zz-xdebug.ini
COPY common/conf/disable-opcache.ini /usr/local/etc/php/conf.d/zz-opcache.ini
COPY --chmod=755 common/entrypoint-dev.sh /usr/local/bin/entrypoint.sh

ENV SENDMAIL_PATH=/usr/local/bin/mhsendmail \
    MAGENTO_RUN_MODE=developer \
    ENABLE_SSL_DEV=true \
    XDEBUG_MODE=debug \
    XDEBUG_CLIENT_HOST=host.docker.internal \
    XDEBUG_CLIENT_PORT=9003 \
    XDEBUG_START_WITH_REQUEST=trigger \
    XDEBUG_IDEKEY=PHPSTORM

FROM ${BUILD_TYPE} AS final

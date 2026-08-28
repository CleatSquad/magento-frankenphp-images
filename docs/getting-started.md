# Getting Started

This guide explains how to use the Magento FrankenPHP Docker images.

## Available Images

| Tag | PHP | Type | Description |
|-----|-----|------|-------------|
| `php8.5-fp1.12.7-base` | 8.5 | Base | Production ready |
| `php8.5-fp1.12.7-dev` | 8.5 | Dev | With Xdebug |
| `php8.4-fp1.12.7-base` | 8.4 | Base | Production ready |
| `php8.4-fp1.12.7-dev` | 8.4 | Dev | With Xdebug |
| `php8.3-fp1.12.7-base` | 8.3 | Base | Production ready |
| `php8.3-fp1.12.7-dev` | 8.3 | Dev | With Xdebug |
| `php8.2-fp1.12.7-base` | 8.2 | Base | Production ready (EOL 2026-12-31, upgrade recommended) |
| `php8.2-fp1.12.7-dev` | 8.2 | Dev | With Xdebug (EOL 2026-12-31, upgrade recommended) |
| `latest` | 8.4 | Base | Default |
| `base` | 8.4 | Base | Alias |
| `dev` | 8.4 | Dev | Alias |

## Quick Start

### Development

```yaml
services:
  app:
    image: mohelmrabet/magento-frankenphp:php8.4-fp1.12.7-dev
    environment:
      - USER_ID=1000
      - GROUP_ID=1000
    volumes:
      - ./src:/var/www/html
    ports:
      - "80:80"
      - "443:443"
```

### Production

```dockerfile
FROM mohelmrabet/magento-frankenphp:php8.4-fp1.12.7-base

COPY --chown=www-data:www-data . /var/www/html/

USER www-data
RUN composer install --no-dev --optimize-autoloader
RUN bin/magento setup:di:compile
RUN bin/magento setup:static-content:deploy -f
```

## Features

### Base Image
- ✅ PHP 8.2, 8.3, 8.4, 8.5
- ✅ FrankenPHP 1.12.7
- ✅ All Magento PHP extensions
- ✅ Composer 2
- ✅ OPcache optimized

### Dev Image
- ✅ Everything in Base +
- ✅ Xdebug 3
- ✅ mkcert (local HTTPS)
- ✅ Self-signed SSL certificates (auto-generated)
- ✅ git
- ✅ Mailhog support
- ✅ Runtime UID/GID mapping

## PHP Extensions

```
bcmath, gd, intl, mbstring, opcache, pdo_mysql, soap, xsl, zip, sockets, ftp, sodium, redis, apcu
```

## Environment Variables (Dev)

| Variable | Default | Description |
|----------|---------|-------------|
| `USER_ID` | `1000` | UID www-data is remapped to at startup (matches host file ownership on bind mounts) |
| `GROUP_ID` | `1000` | GID www-data is remapped to at startup |
| `MAGENTO_RUN_MODE` | `developer` | Magento mode |
| `SERVER_NAME` | `localhost` | Server hostname for SSL |
| `ENABLE_SSL_DEV` | `true` | Generate a locally-trusted certificate with mkcert at startup |
| `CADDY_TLS_CONFIG` | *(auto)* | Set explicitly to skip mkcert and use `internal` or your own `cert key` paths |
| `CAROOT` | *(mkcert default)* | Path to a shared mkcert CA (see [Configuration](configuration.md#trusted-local-https-mkcert)) so generated certs are trusted by the host |

## See Also

- [Xdebug Configuration](xdebug.md)
- [Caddyfile Configuration](Caddyfile.md)
- [Configuration Guide](configuration.md)

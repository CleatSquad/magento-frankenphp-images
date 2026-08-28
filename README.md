# Magento FrankenPHP Docker Images

<p align="center">
  <img src="https://frankenphp.dev/img/logo_darkbg.svg" width="150" alt="FrankenPHP Logo" />
</p>

<p align="center">
  <a href="https://hub.docker.com/r/mohelmrabet/magento-frankenphp"><img src="https://img.shields.io/docker/pulls/mohelmrabet/magento-frankenphp.svg?logo=docker" alt="Docker Pulls" /></a>
  <img src="https://img.shields.io/badge/magento-2.4.x-orange.svg?logo=magento" alt="Magento 2.4.x" />
  <img src="https://img.shields.io/badge/php-8.2%20|%208.3%20|%208.4%20|%208.5-blue.svg?logo=php" alt="PHP Versions" />
  <img src="https://img.shields.io/badge/frankenphp-1.12-purple.svg" alt="FrankenPHP 1.12" />
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License MIT" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/HTTP%2F3-enabled-success.svg?logo=http" alt="HTTP/3" />
  <img src="https://img.shields.io/badge/Brotli-enabled-success.svg" alt="Brotli" />
  <img src="https://img.shields.io/badge/Early%20Hints-enabled-success.svg" alt="Early Hints" />
  <img src="https://img.shields.io/badge/TLS-1.3-success.svg?logo=letsencrypt" alt="TLS 1.3" />
  <img src="https://img.shields.io/badge/JIT-enabled-success.svg?logo=php" alt="JIT" />
</p>

🚀 High-performance Docker images for Magento 2 with [FrankenPHP](https://frankenphp.dev/).

## Supported Tags

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

### Performance Features
- 🚀 **HTTP/3 (QUIC)** - 10-50% faster page loads
- ⚡ **Early Hints (HTTP 103)** - Preload critical resources
- 📦 **Brotli Compression** - 20-25% better compression than gzip
- 🎯 **Optimized Caching** - Immutable cache headers for static assets
- 🔒 **TLS 1.3** - Faster handshakes with 0-RTT resumption
- 🎨 **Modern Image Formats** - AVIF, WebP support with Vary headers

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
| `CAROOT` | *(mkcert default)* | Path to a shared mkcert CA (see below) so generated certs are trusted by the host |

### Trusted local HTTPS (mkcert)

On startup, the dev image generates a TLS certificate for `SERVER_NAME` using
[mkcert](https://github.com/FiloSottile/mkcert), stored in the `/data/caddy/mkcert`
volume. By default this uses a CA generated inside the container, which your
host browser won't trust yet — you'll still see a warning once, and can
inspect/accept it manually.

To make the browser trust it automatically, share your host's mkcert CA with
the container:

```bash
./bin/setup-ssl
```

This installs mkcert's CA in your host trust stores and prints the
`docker-compose.yml` volume/env snippet to mount that CA into the container
(`CAROOT`), so the container signs its certificate with the same CA the host
already trusts. Restart the container afterwards.

Set `ENABLE_SSL_DEV=false` or `CADDY_TLS_CONFIG=internal` to fall back to
Caddy's built-in self-signed TLS instead.

## Xdebug Configuration (Dev)

Xdebug can be configured via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `XDEBUG_MODE` | `debug` | Xdebug mode (debug, coverage, develop, profile, trace, off) |
| `XDEBUG_CLIENT_HOST` | `host.docker.internal` | IDE host address |
| `XDEBUG_CLIENT_PORT` | `9003` | IDE listening port |
| `XDEBUG_START_WITH_REQUEST` | `trigger` | When to start debugging (trigger, yes, no) |
| `XDEBUG_IDEKEY` | `PHPSTORM` | IDE key for session identification |

Example:

```yaml
services:
  app:
    image: mohelmrabet/magento-frankenphp:dev
    environment:
      XDEBUG_MODE: debug
      XDEBUG_CLIENT_HOST: host.docker.internal
      XDEBUG_CLIENT_PORT: 9003
```

## Caddyfile Configuration

The Caddyfile can be customized by mounting your own template:

```yaml
volumes:
  - ./my-Caddyfile.template:/etc/caddy/Caddyfile.template:ro
```

See the [Caddyfile Configuration Guide](docs/Caddyfile.md) for detailed documentation.

## Links

- 🐳 [Docker Hub](https://hub.docker.com/r/mohelmrabet/magento-frankenphp)
- 📦 [GitHub](https://github.com/mohaelmrabet/magento-frankenphp-images)
- 🚀 [FrankenPHP](https://frankenphp.dev/)
- 🔐 [Security Policy](SECURITY.md)
- 📖 [Contributing](CONTRIBUTING.md)
- 📜 [Code of Conduct](CODE_OF_CONDUCT.md)

## Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](docs/getting-started.md) | Installation and initial setup |
| [Configuration](docs/configuration.md) | Environment variables and settings |
| [Caddyfile](docs/Caddyfile.md) | Web server configuration |
| [Xdebug](docs/xdebug.md) | Debugging with Xdebug |
| [Performance](docs/performance.md) | HTTP/3, Early Hints, Brotli optimization |

## License

MIT — see [LICENSE](LICENSE.txt)

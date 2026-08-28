# Configuration Guide

This guide covers all configuration options for the Magento FrankenPHP Docker images.

## Environment Variables

### Core Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_NAME` | `localhost` | Domain name for the server |
| `USER_ID` | `1000` | UID for www-data user (dev) |
| `GROUP_ID` | `1000` | GID for www-data user (dev) |
| `MAGENTO_RUN_MODE` | `developer` | Magento run mode |

### SSL Variables (Dev)

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_SSL_DEV` | `true` | Generate a locally-trusted certificate with mkcert at startup |
| `CADDY_TLS_CONFIG` | (empty, auto) | Set explicitly to skip mkcert and use `internal` or your own `cert key` paths |
| `CAROOT` | (mkcert default) | Path to a shared mkcert CA so generated certs are trusted by the host |

### Caddy Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CADDY_GLOBAL_OPTIONS` | (empty) | Global Caddy options |
| `FRANKENPHP_CONFIG` | (empty) | FrankenPHP-specific config |
| `CADDY_EXTRA_CONFIG` | (empty) | Additional config blocks |
| `CADDY_SERVER_EXTRA_DIRECTIVES` | (empty) | Extra server directives |

## PHP Extensions

All Magento-required extensions are pre-installed:

```
bcmath, gd, intl, mbstring, opcache, pdo_mysql, soap, xsl, zip, sockets, ftp, sodium, redis, apcu
```

## PHP Configuration

### OPcache (Production)

```ini
opcache.enable=1
opcache.memory_consumption=512
opcache.max_accelerated_files=130986
opcache.validate_timestamps=0
```

### Xdebug (Development)

The dev image includes Xdebug with configurable settings via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `XDEBUG_MODE` | `debug` | Xdebug mode (debug, coverage, develop, profile, trace, off) |
| `XDEBUG_CLIENT_HOST` | `host.docker.internal` | IDE host address |
| `XDEBUG_CLIENT_PORT` | `9003` | IDE listening port |
| `XDEBUG_START_WITH_REQUEST` | `trigger` | When to start debugging (trigger, yes, no) |
| `XDEBUG_IDEKEY` | `PHPSTORM` | IDE key for session identification |

Example configuration:

```yaml
services:
  app:
    image: mohelmrabet/magento-frankenphp:dev
    environment:
      XDEBUG_MODE: debug
      XDEBUG_CLIENT_HOST: host.docker.internal
      XDEBUG_CLIENT_PORT: 9003
      XDEBUG_START_WITH_REQUEST: trigger
      XDEBUG_IDEKEY: PHPSTORM
```

**Triggering Xdebug:**
- Add `?XDEBUG_SESSION=PHPSTORM` to URL
- Use browser extension (Xdebug Helper)

For detailed Xdebug configuration including IDE setup, CLI debugging, and troubleshooting, see the [Xdebug Configuration Guide](xdebug.md).

## SSL Certificates

### Development (mkcert)

On startup, the dev image generates a TLS certificate for `SERVER_NAME` using
[mkcert](https://github.com/FiloSottile/mkcert), stored in the `/data/caddy/mkcert`
volume. By default this uses a CA generated inside the container, which your
host browser won't trust yet — you'll see a warning once, and can inspect/accept
it manually.

**Option 1: Accept browser warning**

Click "Advanced" → "Proceed to site" in browser.

**Option 2: Trust the certificate automatically**

Share your host's mkcert CA with the container:

```bash
./bin/setup-ssl
```

This installs mkcert's CA in your host trust stores and prints the
`docker-compose.yml` volume/env snippet to mount that CA into the container
(`CAROOT`), so the container signs its certificate with the same CA the host
already trusts. Restart the container afterwards.

**Option 3: Fall back to Caddy's internal self-signed TLS**

```yaml
environment:
  ENABLE_SSL_DEV: "false"
```

or set `CADDY_TLS_CONFIG: internal` to skip mkcert explicitly.

### Production (Let's Encrypt)

Caddy handles SSL automatically:

```yaml
environment:
  SERVER_NAME: yourdomain.com www.yourdomain.com
```

## Security

The Caddyfile includes these security features:

- ✅ Blocked: `.git`, `.env`, `.htaccess`, `.htpasswd`
- ✅ Directory traversal protection
- ✅ XML files in `/errors/` blocked
- ✅ Customer/downloadable media protected
- ✅ X-Frame-Options headers
- ✅ Automatic HTTPS

## Performance Tuning

### Docker Resources

Recommended minimums:
- **Memory**: 8GB
- **CPUs**: 4

### macOS/Windows File Sync

For better performance:

```yaml
# docker-compose.override.yml
services:
  app:
    volumes:
      - type: bind
        source: ./src
        target: /var/www/html
        consistency: cached
```

## Troubleshooting

### Permission Issues

```bash
docker compose exec app chown -R www-data:www-data var generated pub
```

### Container Won't Start

```bash
docker compose logs app
docker compose exec app caddy validate --config /etc/caddy/Caddyfile
```

## See Also

- [Xdebug Configuration](xdebug.md)
- [Caddyfile Configuration](Caddyfile.md)
- [Getting Started](getting-started.md)

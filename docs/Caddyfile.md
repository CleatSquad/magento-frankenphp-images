# Caddyfile Configuration Guide

This document explains how to configure and customize the Caddy web server for your Magento 2 FrankenPHP Docker environment.

## Overview

This Docker image uses [FrankenPHP](https://frankenphp.dev/), which is built on top of [Caddy](https://caddyserver.com/). The Caddyfile is the configuration file that controls how the web server handles requests.

### Image Types

| Image | SSL Behavior | Use Case |
|-------|--------------|----------|
| `base` | Standard Caddy SSL (automatic HTTPS) | Production |
| `dev` | Self-signed SSL via mkcert | Development |

## Template System

The Caddyfile uses a template system that allows you to customize the configuration without rebuilding the image.

### Default Template Location

```
/etc/caddy/Caddyfile.template
```

### How It Works

1. At container startup, the entrypoint script copies the template to `/etc/caddy/Caddyfile`
2. Caddy processes environment variable placeholders at runtime
3. You can mount your own template to override the default configuration

### Mounting a Custom Template

```yaml
# docker-compose.yml
services:
  app:
    image: mohelmrabet/magento-frankenphp:dev
    volumes:
      - ./my-custom-Caddyfile.template:/etc/caddy/Caddyfile.template:ro
```

## Environment Variables

The Caddyfile template supports the following environment variables:

### Core Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_NAME` | `localhost` | The server hostname(s). Supports multiple domains separated by spaces. |
| `CADDY_GLOBAL_OPTIONS` | (empty) | Global Caddy options in the top-level block |
| `FRANKENPHP_CONFIG` | (empty) | FrankenPHP-specific configuration |
| `CADDY_EXTRA_CONFIG` | (empty) | Additional configuration blocks outside the server block |
| `CADDY_SERVER_EXTRA_DIRECTIVES` | (empty) | Extra directives inside the server block |

### Dev Image Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_SSL_DEV` | `true` | Enable/disable self-signed SSL certificate generation |

### Examples

```yaml
# docker-compose.yml
services:
  app:
    image: mohelmrabet/magento-frankenphp:dev
    environment:
      - SERVER_NAME=magento.localhost
      - CADDY_GLOBAL_OPTIONS=debug
```

```yaml
# Multiple domains
environment:
  - SERVER_NAME=magento.localhost www.magento.localhost admin.magento.localhost
```

## SSL/TLS Configuration

### Development (dev image)

The dev image uses Caddy's built-in `tls internal` directive by default, which automatically generates self-signed SSL certificates.

#### Fixing `net::ERR_CERT_AUTHORITY_INVALID` Error

By default, browsers don't trust the self-signed certificates. You have two options to fix this:

**Option 1: Trust the certificate manually in your browser (Quick)**

1. Open your site in the browser (e.g., `https://magento.localhost`)
2. Click "Advanced" or "Show Details"
3. Click "Proceed to site" or "Accept the Risk and Continue"

**Option 2: Keep using internal TLS (Default)**

By default, the container uses `tls internal` which generates self-signed certificates automatically. The only downside is the browser warning.

### Production (base image)

For production, Caddy handles SSL automatically via Let's Encrypt. Configure your domain:

```yaml
environment:
  - SERVER_NAME=yourdomain.com www.yourdomain.com
```

For custom SSL certificates:

```yaml
volumes:
  - ./certs/cert.pem:/data/caddy/certificates/custom/cert.pem:ro
  - ./certs/key.pem:/data/caddy/certificates/custom/key.pem:ro
environment:
  - CADDY_SERVER_EXTRA_DIRECTIVES=tls /data/caddy/certificates/custom/cert.pem /data/caddy/certificates/custom/key.pem
```

## Common Customizations

### Adding Custom Headers

```yaml
environment:
  - CADDY_SERVER_EXTRA_DIRECTIVES=header X-Custom-Header "MyValue"
```

### Enabling Debug Mode

```yaml
environment:
  - CADDY_GLOBAL_OPTIONS=debug
```

### Configuring HTTP/3

HTTP/3 is enabled by default in Caddy. To disable it:

```yaml
environment:
  - CADDY_GLOBAL_OPTIONS=servers { protocols h1 h2 }
```

## External Resources

### Caddy Documentation

- 📚 [Caddyfile Concepts](https://caddyserver.com/docs/caddyfile/concepts)
- 📚 [Caddyfile Directives](https://caddyserver.com/docs/caddyfile/directives)
- 📚 [Caddy Placeholders](https://caddyserver.com/docs/caddyfile/concepts#placeholders)
- 📚 [TLS Configuration](https://caddyserver.com/docs/caddyfile/directives/tls)
- 📚 [Automatic HTTPS](https://caddyserver.com/docs/automatic-https)

### FrankenPHP Documentation

- 📚 [FrankenPHP Documentation](https://frankenphp.dev/docs/)
- 📚 [FrankenPHP Configuration](https://frankenphp.dev/docs/config/)
- 📚 [Worker Mode](https://frankenphp.dev/docs/worker/)

### Magento 2 Resources

- 📚 [Magento 2 DevDocs](https://developer.adobe.com/commerce/docs/)
- 📚 [Magento Security Best Practices](https://experienceleague.adobe.com/docs/commerce-operations/implementation-playbook/best-practices/launch/security-best-practices.html)

## Troubleshooting

### SSL Certificate Issues

**Problem:** Browser shows "Not Secure" warning

**Solution:** Accept the self-signed certificate in your browser (click Advanced → Proceed)

### Configuration Not Applied

**Problem:** Changes to environment variables not taking effect

**Solution:**
1. Restart the container: `docker compose restart app`
2. Verify the Caddyfile: `docker compose exec app cat /etc/caddy/Caddyfile`

### Debug Caddy Configuration

```bash
# Validate Caddyfile syntax
docker compose exec app frankenphp validate --config /etc/caddy/Caddyfile

# Check Caddy logs
docker compose logs app | grep -i caddy
```

### Permission Issues

```bash
# Fix permissions on Caddy data
docker compose exec app chown -R www-data:www-data /data/caddy /etc/caddy
```

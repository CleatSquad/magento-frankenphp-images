#!/bin/bash
set -e

# --- UID/GID mapping -------------------------------------------------------
# Aligns the www-data user inside the container with the host user so files
# created by FrankenPHP/Composer/Magento CLI on the bind-mounted volume are
# owned by the developer, not by an arbitrary container UID.
USER_ID="${USER_ID:-1000}"
GROUP_ID="${GROUP_ID:-1000}"

if [ "$(id -u)" = "0" ]; then
    CURRENT_UID=$(id -u www-data)
    CURRENT_GID=$(id -g www-data)

    if [ "$CURRENT_UID" != "$USER_ID" ] || [ "$CURRENT_GID" != "$GROUP_ID" ]; then
        echo "👤 Remapping www-data to UID=${USER_ID} GID=${GROUP_ID} (was ${CURRENT_UID}:${CURRENT_GID})"
        groupmod -o -g "$GROUP_ID" www-data
        usermod -o -u "$USER_ID" www-data
    fi

    # Always align these container-owned dirs with www-data: needed even on
    # the default 1000:1000 mapping, since /config/caddy ships root-owned and
    # FrankenPHP now runs as www-data (dropped via gosu below).
    chown -R www-data:www-data /var/www/.composer /etc/caddy /data/caddy /config/caddy
fi

# Process Caddyfile template
# If a custom template is mounted, use it; otherwise use the default
TEMPLATE_SOURCE="/etc/caddy/Caddyfile.template"
CADDYFILE_TARGET="/etc/caddy/Caddyfile"

# Check if template exists (either mounted or default)
if [ -f "$TEMPLATE_SOURCE" ]; then
    # Copy template to target (allows environment variable substitution by Caddy)
    cp "$TEMPLATE_SOURCE" "$CADDYFILE_TARGET"
    echo "📝 Caddyfile template processed: $TEMPLATE_SOURCE -> $CADDYFILE_TARGET"
fi

# Xdebug configuration is now handled via environment variables
# Xdebug 3.x natively reads XDEBUG_MODE and XDEBUG_CONFIG from environment
# See: https://xdebug.org/docs/all_settings
if [ -n "$XDEBUG_MODE" ] && [ "$XDEBUG_MODE" != "off" ]; then
    echo "🐛 Xdebug enabled: mode=${XDEBUG_MODE}"
    # Build XDEBUG_CONFIG from individual environment variables if not already set
    if [ -z "$XDEBUG_CONFIG" ]; then
        XDEBUG_CONFIG="client_host=${XDEBUG_CLIENT_HOST:-host.docker.internal}"
        XDEBUG_CONFIG="$XDEBUG_CONFIG client_port=${XDEBUG_CLIENT_PORT:-9003}"
        XDEBUG_CONFIG="$XDEBUG_CONFIG start_with_request=${XDEBUG_START_WITH_REQUEST:-trigger}"
        XDEBUG_CONFIG="$XDEBUG_CONFIG idekey=${XDEBUG_IDEKEY:-PHPSTORM}"
        export XDEBUG_CONFIG
    fi
    echo "   XDEBUG_CONFIG: $XDEBUG_CONFIG"
fi

# Display SSL information
SSL_DOMAIN="${SERVER_NAME:-localhost}"
SSL_DOMAIN=$(echo "$SSL_DOMAIN" | sed -E 's|^https?://||' | sed -E 's|:[0-9]+$||')

# --- mkcert locally-trusted certificates ------------------------------------
# When enabled (default), generate a certificate trusted by the host's local
# CA via mkcert, so browsers don't show the "not secure" warning that comes
# with Caddy's internal self-signed TLS. Falls back to internal TLS if mkcert
# fails (e.g. the host CA was never installed via `bin/setup-ssl`) or if the
# user already set CADDY_TLS_CONFIG explicitly.
if [ "${ENABLE_SSL_DEV:-true}" = "true" ] && [ -z "$CADDY_TLS_CONFIG" ] && command -v mkcert >/dev/null 2>&1; then
    CERT_DIR="/data/caddy/mkcert"
    mkdir -p "$CERT_DIR"

    if [ ! -f "$CERT_DIR/cert.pem" ] || [ ! -f "$CERT_DIR/key.pem" ]; then
        echo "🔏 Generating mkcert certificate for: $SSL_DOMAIN"
        if mkcert -install >/tmp/mkcert-install.log 2>&1 \
            && mkcert -cert-file "$CERT_DIR/cert.pem" -key-file "$CERT_DIR/key.pem" \
                "$SSL_DOMAIN" localhost 127.0.0.1 ::1 >/tmp/mkcert-gen.log 2>&1; then
            echo "✅ mkcert certificate generated: $CERT_DIR"
        else
            echo "⚠️  mkcert failed, falling back to Caddy's internal TLS (see /tmp/mkcert-*.log)"
            rm -f "$CERT_DIR/cert.pem" "$CERT_DIR/key.pem"
        fi
    fi

    if [ -f "$CERT_DIR/cert.pem" ] && [ -f "$CERT_DIR/key.pem" ]; then
        export CADDY_TLS_CONFIG="$CERT_DIR/cert.pem $CERT_DIR/key.pem"
        [ "$(id -u)" = "0" ] && chown -R www-data:www-data "$CERT_DIR"
    fi
fi

echo "🔐 SSL Mode: ${CADDY_TLS_CONFIG:-internal}"
echo "🌐 Server Name: $SSL_DOMAIN"

if [ "${CADDY_TLS_CONFIG:-internal}" = "internal" ]; then
    echo "📌 Using Caddy's internal TLS (self-signed certificates)"
    echo "   To trust certificates in your browser, either:"
    echo "   1. Accept the certificate manually (click Advanced → Proceed)"
    echo "   2. Or run './bin/setup-ssl' on the host so mkcert's local CA is trusted"
else
    echo "📌 Using mkcert-issued certificate trusted by the host's local CA"
fi

# Drop root privileges before starting FrankenPHP, now that UID/GID mapping
# and cert generation (which need root) are done.
RUN_AS=""
if [ "$(id -u)" = "0" ]; then
    RUN_AS="gosu www-data"
fi

# Start FrankenPHP
if [ $# -eq 0 ]; then
    # shellcheck disable=SC2086
    exec $RUN_AS frankenphp run --config /etc/caddy/Caddyfile --watch
fi

# shellcheck disable=SC2086
exec $RUN_AS "$@"

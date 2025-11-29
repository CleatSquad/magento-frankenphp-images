#!/bin/bash
set -e

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

echo "🔐 SSL Mode: ${CADDY_TLS_CONFIG:-internal}"
echo "🌐 Server Name: $SSL_DOMAIN"

# If using internal TLS (default), Caddy will auto-generate self-signed certificates
if [ "${CADDY_TLS_CONFIG:-internal}" = "internal" ]; then
    echo "📌 Using Caddy's internal TLS (self-signed certificates)"
    echo "   To trust certificates in your browser, either:"
    echo "   1. Accept the certificate manually (click Advanced → Proceed)"
    echo "   2. Or run './bin/setup-ssl' on the host to generate trusted certificates"
fi

# Start FrankenPHP
if [ $# -eq 0 ]; then
    exec frankenphp run --config /etc/caddy/Caddyfile --watch
fi

exec "$@"

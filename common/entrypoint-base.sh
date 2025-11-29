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

# Start FrankenPHP
if [ $# -eq 0 ]; then
    exec frankenphp run --config /etc/caddy/Caddyfile --watch
fi

exec "$@"

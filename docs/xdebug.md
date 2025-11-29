# Xdebug Configuration Guide

This guide explains how to configure and use Xdebug for debugging your Magento 2 application with the FrankenPHP Docker environment.

## Prerequisites

- Use the **development image** (`mohelmrabet/magento-frankenphp:dev` or `php8.4-fp1.10.1-dev`)
- PHPStorm, VS Code, or another IDE with Xdebug support

## Default Configuration

The development image comes with Xdebug pre-configured with the following default settings:

```ini
xdebug.mode = debug
xdebug.client_host = host.docker.internal
xdebug.client_port = 9003
xdebug.start_with_request = trigger
xdebug.idekey = PHPSTORM
```

## Environment Variable Configuration

You can customize Xdebug settings using environment variables. These are processed at container startup:

| Variable | Default | Description |
|----------|---------|-------------|
| `XDEBUG_MODE` | `debug` | Xdebug mode (debug, coverage, develop, profile, trace, off) |
| `XDEBUG_CLIENT_HOST` | `host.docker.internal` | IDE host address |
| `XDEBUG_CLIENT_PORT` | `9003` | IDE listening port |
| `XDEBUG_START_WITH_REQUEST` | `trigger` | When to start debugging (trigger, yes, no) |
| `XDEBUG_IDEKEY` | `PHPSTORM` | IDE key for session identification |

### Example: docker-compose.yml

```yaml
services:
  app:
    image: mohelmrabet/magento-frankenphp:php8.4-fp1.10.1-dev
    environment:
      XDEBUG_MODE: debug
      XDEBUG_CLIENT_HOST: host.docker.internal
      XDEBUG_CLIENT_PORT: 9003
      XDEBUG_START_WITH_REQUEST: trigger
      XDEBUG_IDEKEY: PHPSTORM
```

### Example: Docker Run

```bash
docker run -d \
  -e XDEBUG_MODE=debug,coverage \
  -e XDEBUG_CLIENT_HOST=192.168.1.100 \
  -e XDEBUG_CLIENT_PORT=9003 \
  mohelmrabet/magento-frankenphp:dev
```

## IDE Configuration

### PHPStorm Setup

1. **Configure Xdebug Port**
   - Go to **Settings > PHP > Debug**
   - Set **Xdebug port** to `9003`
   - Enable **Can accept external connections**

2. **Configure Server Mapping**
   - Go to **Settings > PHP > Servers**
   - Click **+** to add a new server:
     - **Name**: `magento.localhost` (or your `SERVER_NAME`)
     - **Host**: `magento.localhost`
     - **Port**: `443`
     - **Debugger**: `Xdebug`
     - **Use path mappings**: ✅ Yes
     - Map `/var/www/html` → your local `src/` directory

3. **Start Listening**
   - Go to **Run > Start Listening for PHP Debug Connections** in the menu
   - Or click the **Start Listening for PHP Debug Connections** button in the toolbar
   - Or use the keyboard shortcut: `Ctrl+Alt+D` (Windows/Linux) / `Cmd+Alt+D` (macOS)

### VS Code Setup

1. **Install PHP Debug Extension**
   - Install the [PHP Debug](https://marketplace.visualstudio.com/items?itemName=xdebug.php-debug) extension by Xdebug

2. **Create Launch Configuration**
   - Create `.vscode/launch.json` in your project root:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Listen for Xdebug",
            "type": "php",
            "request": "launch",
            "port": 9003,
            "pathMappings": {
                "/var/www/html": "${workspaceFolder}/src"
            }
        }
    ]
}
```

3. **Start Debugging**
   - Go to **Run and Debug** panel (Ctrl+Shift+D / Cmd+Shift+D)
   - Select "Listen for Xdebug" from the dropdown
   - Click the green play button ▶️

## Triggering Xdebug

Since `xdebug.start_with_request = trigger` is configured (for performance), you need to trigger Xdebug manually:

### Option 1: URL Parameter

Add `?XDEBUG_SESSION=PHPSTORM` to any URL:

```
https://magento.localhost/?XDEBUG_SESSION=PHPSTORM
https://magento.localhost/admin?XDEBUG_SESSION=PHPSTORM
```

### Option 2: Browser Extension (Recommended)

Install a browser extension that automatically manages the Xdebug session:

- **Chrome**: [Xdebug Helper](https://chrome.google.com/webstore/detail/xdebug-helper/eadndfjplgieldjbigjakmdgkmoaaaoc)
- **Firefox**: [Xdebug Helper](https://addons.mozilla.org/en-US/firefox/addon/xdebug-helper-for-firefox/)
- **Edge**: [Xdebug Helper](https://microsoftedge.microsoft.com/addons/detail/xdebug-helper/ggnngifabofaddiejjeagbaebkejomen)

Configure the extension:
1. Right-click the extension icon and select **Options**
2. Set **IDE key** to `PHPSTORM` (or your IDE key)
3. Click the extension icon and select **Debug** when you want to debug

## Debugging CLI Commands

To debug Magento CLI commands (e.g., `bin/magento`), you need to enable Xdebug explicitly:

```bash
# Enter the container
docker compose exec app bash

# Run command with Xdebug enabled
XDEBUG_SESSION=1 bin/magento cache:flush
```

Or from outside the container:

```bash
docker compose exec -e XDEBUG_SESSION=1 app bin/magento cache:flush
```

## Available Xdebug Modes

| Mode | Description |
|------|-------------|
| `off` | Disable Xdebug |
| `debug` | Step debugging |
| `develop` | Development helpers (var_dump improvements) |
| `coverage` | Code coverage for PHPUnit |
| `profile` | Performance profiling |
| `trace` | Function trace |

You can combine modes: `xdebug.mode = debug,develop`

## Troubleshooting

### Xdebug Not Connecting

1. **Verify Xdebug is installed**:
   ```bash
   docker compose exec app php -v
   # Should show "with Xdebug v3.x.x"
   ```

2. **Check Xdebug configuration**:
   ```bash
   docker compose exec app php -i | grep xdebug
   ```

3. **Verify port is open** on your host:
   - Make sure your IDE is listening on port 9003
   - Check firewall settings

### Connection Refused on Linux

On Linux, `host.docker.internal` might not resolve correctly. Use your host's IP:

1. Find your Docker bridge IP:
   ```bash
   ip addr show docker0
   ```

2. Override client host:
   ```yaml
   environment:
     XDEBUG_CLIENT_HOST: 172.17.0.1  # Replace with your IP
   ```

Or add this to your `docker-compose.yml`:

```yaml
services:
  app:
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

## See Also

- [Configuration Guide](configuration.md)
- [Xdebug Official Documentation](https://xdebug.org/docs/)

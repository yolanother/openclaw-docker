# OpenClaw (Clawbot) Docker Image

Pre-built Docker image for [OpenClaw](https://github.com/openclaw/openclaw) — run your AI assistant in seconds without building from source.

> 🔄 **Always Up-to-Date:** This image automatically builds daily and checks for new OpenClaw releases every 6 hours, ensuring you always have the latest version.

## One-Line Install (Recommended)

### Linux / macOS

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/phioranex/openclaw-docker/main/install.sh)
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/phioranex/openclaw-docker/main/install.ps1 | iex
```

> **Note for Windows users:** Make sure Docker Desktop is installed and running. You can also use WSL2 with the Linux installation command.

This will:
- ✅ Check prerequisites (Docker, Docker Compose)
- ✅ Download necessary files
- ✅ Pull the pre-built image
- ✅ Run the onboarding wizard
- ✅ Start the gateway

### Install Options

**Linux / macOS:**

### Install Options

**Linux / macOS:**

```bash
# Just pull the image (no setup)
bash <(curl -fsSL https://raw.githubusercontent.com/phioranex/openclaw-docker/main/install.sh) --pull-only

# Skip onboarding (if already configured)
bash <(curl -fsSL https://raw.githubusercontent.com/phioranex/openclaw-docker/main/install.sh) --skip-onboard

# Don't start gateway after setup
bash <(curl -fsSL https://raw.githubusercontent.com/phioranex/openclaw-docker/main/install.sh) --no-start

# Custom install directory
bash <(curl -fsSL https://raw.githubusercontent.com/phioranex/openclaw-docker/main/install.sh) --install-dir /opt/openclaw
```

**Windows (PowerShell):**

```powershell
# Just pull the image (no setup)
irm https://raw.githubusercontent.com/phioranex/openclaw-docker/main/install.ps1 | iex -PullOnly

# Skip onboarding (if already configured)
irm https://raw.githubusercontent.com/phioranex/openclaw-docker/main/install.ps1 | iex -SkipOnboard

# Don't start gateway after setup
irm https://raw.githubusercontent.com/phioranex/openclaw-docker/main/install.ps1 | iex -NoStart

# Custom install directory
$env:TEMP_INSTALL_SCRIPT = irm https://raw.githubusercontent.com/phioranex/openclaw-docker/main/install.ps1; Invoke-Expression $env:TEMP_INSTALL_SCRIPT -InstallDir "C:\openclaw"
```

## Manual Install

### Quick Start

```bash
# Pull the image
docker pull ghcr.io/phioranex/openclaw-docker:latest

# Run onboarding (first time setup)
docker run -it --rm \
  -v ~/.openclaw:/home/node/.openclaw \
  -v ~/.openclaw/workspace:/home/node/.openclaw/workspace \
  ghcr.io/phioranex/openclaw-docker:latest onboard

# Start the gateway
docker run -d \
  --name openclaw \
  --restart unless-stopped \
  -v ~/.openclaw:/home/node/.openclaw \
  -v ~/.openclaw/workspace:/home/node/.openclaw/workspace \
  -p 18789:18789 \
  ghcr.io/phioranex/openclaw-docker:latest gateway start --foreground
```

### Using Docker Compose

```bash
# Clone this repo
git clone https://github.com/phioranex/openclaw-docker.git
cd openclaw-docker

# Run onboarding
docker compose run --rm openclaw-cli onboard

# Start the gateway
docker compose up -d openclaw-gateway
```

## Development & Updates

### Update Script

For local development or testing specific branches/PRs, use the included `update.sh` script:

```bash
# Update from main branch (default)
./update.sh

# Test a specific branch or PR
./update.sh --branch feature-name

# Rebuild and run onboarding
./update.sh --init

# Combine options
./update.sh --branch pr-123 --init
```

#### Custom Volume Configuration

Create a `.env.local` file to customize volume paths:

```bash
# Copy the example file
cp .env.local.example .env.local

# Edit with your preferred paths
nano .env.local
```

Example `.env.local`:
```bash
OPENCLAW_VOLUME="/opt/openclaw/config"
OPENCLAW_WORKSPACE_VOLUME="/opt/openclaw/workspace"
```

The update script will:
1. Stop and remove existing containers
2. Rebuild the Docker image from the specified branch
3. Optionally run the onboarding wizard (with `--init`)
4. Start the gateway and proxy containers

## Configuration

During onboarding, you'll configure:
- **AI Provider** (Anthropic Claude, OpenAI, etc.)
- **Channels** (Telegram, WhatsApp, Discord, etc.)
- **Gateway settings**

Config is stored in `~/.openclaw/` and persists across container restarts.

### Network Access

By default, the gateway is configured to accept connections from any network interface (`0.0.0.0`), allowing other devices on your network to connect. 

**Security Note:** If you want to restrict access to localhost only (for added security), you can:
1. Set `OPENCLAW_HOST=127.0.0.1` in your `.env.local` file, or
2. Add it to the environment section in `docker-compose.yml`

When restricted to localhost, only applications running on the same machine can connect to the gateway.

## Available Tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest OpenClaw build (updated daily and on new releases) |
| `vX.Y.Z` | Specific version (if available) |
| `main` | Latest from main branch (cutting edge) |

> **Note:** The `latest` tag is automatically rebuilt daily at 00:00 UTC and whenever OpenClaw releases a new version.

## Volumes

| Path | Purpose |
|------|---------|
| `/home/node/.openclaw` | Config and session data |
| `/home/node/.openclaw/workspace` | Agent workspace |

## Ports

| Port | Purpose |
|------|---------|
| `18789` | Gateway API + Dashboard |
| `18790` | Socat proxy (alternative access) |

> **Network Access:** The gateway binds to `0.0.0.0` (all network interfaces) by default, allowing connections from other systems on your network. To restrict access to localhost only, set `OPENCLAW_HOST=127.0.0.1` in your environment or `.env.local` file.

## Links

- [OpenClaw Website](https://openclaw.ai/)
- [OpenClaw Docs](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Discord Community](https://discord.gg/clawd)

## Troubleshooting

### Permission Issues on Synology NAS

If you encounter `EACCES: permission denied` errors when running on Synology NAS:

1. **Option 1: Run install script with sudo (Recommended)**
   ```bash
   sudo bash <(curl -fsSL https://raw.githubusercontent.com/phioranex/openclaw-docker/main/install.sh)
   ```
   The script will automatically:
   - Set proper ownership (UID 1000) for the container user
   - Configure your user account to access the files
   - Update docker-compose.yml to use the correct home directory

2. **Option 2: Fix permissions manually**
   ```bash
   # RECOMMENDED: Set ownership to UID 1000 with group access (most secure)
   sudo chown -R 1000:$(id -g) ~/.openclaw
   sudo chmod -R u+rwX,g+rwX,o-rwx ~/.openclaw
   
   # Alternative: Make directory writable by owner and group (less secure)
   chmod -R 775 ~/.openclaw
   
   # LAST RESORT ONLY: World-writable (least secure, use only if above options fail)
   # chmod -R 777 ~/.openclaw
   ```

3. **Option 3: Use host user mapping**
   Edit `docker-compose.yml` and uncomment the `user: "1000:1000"` line in both services:
   ```yaml
   user: "1000:1000"  # Uncomment this line
   ```

### Telegram Bot Connection Issues

If the Telegram bot cannot find your username or numeric ID:

1. Ensure your container has internet access:
   ```bash
   docker exec openclaw-gateway ping -c 3 api.telegram.org
   ```

2. Check if firewall or network restrictions are blocking Telegram API access

3. Verify your Telegram bot token is correct in `~/.openclaw/openclaw.json`

### Docker Permission Issues (Image Pull)

If you need root/sudo to pull Docker images:

1. Add your user to the docker group:
   ```bash
   sudo usermod -aG docker $USER
   ```

2. Log out and log back in for the changes to take effect

3. Alternatively, use `sudo` when running the install script

## YouTube Tutorial

📺 Watch the installation tutorial: [Coming Soon]

## License

This Docker packaging is provided by [Phioranex](https://phioranex.com).
OpenClaw itself is licensed under MIT — see the [original repo](https://github.com/openclaw/openclaw).

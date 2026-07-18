#!/usr/bin/env bash
#
# V2Ray server installer for Amazon Linux 2023.
# Use only on hosts/infrastructure you are authorized to manage.
#
# Usage:
#   sudo bash install-v2ray-al2023.sh
#
# Optional environment variables:
#   V2RAY_PORT    Listening port (default: random 10000-65000)
#   V2RAY_UUID    VMess user UUID (default: auto-generated)
#   OPEN_FIREWALL Open port in firewalld/iptables (default: true)

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
V2RAY_USER="v2ray"
V2RAY_DIR="/usr/local/etc/v2ray"
V2RAY_BIN_DIR="/usr/local/bin"
V2RAY_LOG_DIR="/var/log/v2ray"
V2RAY_SERVICE="/etc/systemd/system/v2ray.service"

V2RAY_PORT="${V2RAY_PORT:-$((RANDOM % 55000 + 10000))}"
V2RAY_UUID="${V2RAY_UUID:-$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)}"
OPEN_FIREWALL="${OPEN_FIREWALL:-true}"

GITHUB_REPO="v2fly/v2ray-core"
RELEASE_URL="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }

die() { log "ERROR: $*" >&2; exit 1; }

check_root() {
    [[ $EUID -eq 0 ]] || die "This script must be run as root (use sudo)."
}

detect_arch() {
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64)  echo "64" ;;
        aarch64) echo "arm64-v8a" ;;
        armv7l)  echo "armv7a" ;;
        *)       die "Unsupported architecture: $arch" ;;
    esac
}

install_deps() {
    log "Installing dependencies..."
    dnf -y -q update || true
    dnf -y -q install curl unzip ca-certificates || die "Failed to install dependencies"
}

download_v2ray() {
    local arch zip_name download_url tmpdir
    arch="$(detect_arch)"
    zip_name="v2ray-linux-${arch}.zip"

    log "Detecting latest V2Ray release..."
    download_url="$(curl -fsSL "${RELEASE_URL}" | grep -oP '"browser_download_url":\s*"\K[^"]+' | grep "${zip_name}" | head -n1)"
    [[ -n "$download_url" ]] || die "Could not find download URL for ${zip_name}"

    log "Downloading V2Ray: ${download_url}"
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "${tmpdir}"' RETURN

    curl -fsSL -o "${tmpdir}/${zip_name}" "$download_url" || die "Download failed"
    unzip -q "${tmpdir}/${zip_name}" -d "${tmpdir}/extracted" || die "Extraction failed"

    install -Dm755 "${tmpdir}/extracted/v2ray" "${V2RAY_BIN_DIR}/v2ray"
    install -Dm644 "${tmpdir}/extracted/geoip.dat" "${V2RAY_DIR}/geoip.dat" || true
    install -Dm644 "${tmpdir}/extracted/geosite.dat" "${V2RAY_DIR}/geosite.dat" || true

    log "V2Ray installed to ${V2RAY_BIN_DIR}/v2ray"
}

create_user() {
    if ! id -u "$V2RAY_USER" &>/dev/null; then
        log "Creating system user: ${V2RAY_USER}"
        useradd --no-create-home --system --shell /usr/sbin/nologin "$V2RAY_USER"
    fi
}

create_dirs() {
    mkdir -p "${V2RAY_DIR}" "${V2RAY_LOG_DIR}"
    chown -R "${V2RAY_USER}:${V2RAY_USER}" "${V2RAY_DIR}" "${V2RAY_LOG_DIR}"
    chmod 750 "${V2RAY_DIR}" "${V2RAY_LOG_DIR}"
}

generate_config() {
    log "Generating V2Ray config: ${V2RAY_DIR}/config.json"
    cat > "${V2RAY_DIR}/config.json" <<EOF
{
  "log": {
    "access": "${V2RAY_LOG_DIR}/access.log",
    "error": "${V2RAY_LOG_DIR}/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": ${V2RAY_PORT},
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${V2RAY_UUID}",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "tcp"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
    chown "${V2RAY_USER}:${V2RAY_USER}" "${V2RAY_DIR}/config.json"
    chmod 640 "${V2RAY_DIR}/config.json"
}

create_systemd_service() {
    log "Creating systemd service..."
    cat > "$V2RAY_SERVICE" <<EOF
[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
User=${V2RAY_USER}
Group=${V2RAY_USER}
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=${V2RAY_BIN_DIR}/v2ray run -config ${V2RAY_DIR}/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
    chmod 644 "$V2RAY_SERVICE"
    systemctl daemon-reload
    systemctl enable --now v2ray || die "Failed to start v2ray service"
}

open_firewall() {
    [[ "$OPEN_FIREWALL" == "true" ]] || return 0
    log "Opening port ${V2RAY_PORT} in firewall..."

    if command -v firewall-cmd &>/dev/null; then
        firewall-cmd --permanent --add-port="${V2RAY_PORT}/tcp" || true
        firewall-cmd --reload || true
    elif command -v iptables &>/dev/null; then
        iptables -I INPUT -p tcp --dport "${V2RAY_PORT}" -j ACCEPT || true
    else
        log "WARNING: No supported firewall tool found. Open port ${V2RAY_PORT}/tcp manually."
    fi
}

print_summary() {
    local public_ip
    public_ip="$(curl -fsSL -4 https://checkip.amazonaws.com 2>/dev/null || echo '<your-server-ip>')"

    cat <<EOF

========================================================================
V2Ray server installed successfully.
========================================================================

Server IP      : ${public_ip}
Port           : ${V2RAY_PORT}
UUID           : ${V2RAY_UUID}
Protocol       : vmess
Network        : tcp
AlterId        : 0

Config file    : ${V2RAY_DIR}/config.json
Binary         : ${V2RAY_BIN_DIR}/v2ray
Service status : systemctl status v2ray
Logs           : ${V2RAY_LOG_DIR}/access.log
                 ${V2RAY_LOG_DIR}/error.log

Example VMess sharing link (simplified):
  vmess://$(echo -n '{"v":"2","ps":"AL2023-V2Ray","add":"'${public_ip}'","port":"'${V2RAY_PORT}'","id":"'${V2RAY_UUID}'","aid":"0","net":"tcp","type":"none"}' | base64 -w0)

IMPORTANT:
- Use this only on hosts you are authorized to manage.
- Comply with AWS Terms of Service and local laws.
- Consider replacing VMess with VLESS + XTLS/Reality or adding TLS for
  stronger security in production environments.
========================================================================
EOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    check_root
    install_deps
    create_user
    create_dirs
    download_v2ray
    generate_config
    create_systemd_service
    open_firewall
    print_summary
}

main "$@"

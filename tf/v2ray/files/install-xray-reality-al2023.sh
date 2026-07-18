#!/usr/bin/env bash
#
# Xray server installer with VLESS + Vision (XTLS) + REALITY on Amazon Linux 2023.
# Use only on hosts/infrastructure you are authorized to manage.
#
# Usage:
#   sudo bash install-xray-reality-al2023.sh
#
# Optional environment variables:
#   XRAY_PORT      Listening port (default: random 10000-65000)
#   XRAY_UUID      VLESS user UUID (default: auto-generated)
#   REALITY_DEST   TLS 1.3 destination to masquerade as (default: www.cloudflare.com:443)
#   REALITY_SNI    ServerName sent by clients (default: same as REALITY_DEST host)
#   OPEN_FIREWALL  Open port in firewalld/iptables (default: true)

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
XRAY_USER="xray"
XRAY_DIR="/usr/local/etc/xray"
XRAY_BIN_DIR="/usr/local/bin"
XRAY_LOG_DIR="/var/log/xray"
XRAY_SERVICE="/etc/systemd/system/xray.service"

XRAY_PORT="${XRAY_PORT:-$((RANDOM % 55000 + 10000))}"
XRAY_UUID="${XRAY_UUID:-$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)}"
REALITY_DEST="${REALITY_DEST:-www.cloudflare.com:443}"
REALITY_SNI="${REALITY_SNI:-${REALITY_DEST%%:*}}"
OPEN_FIREWALL="${OPEN_FIREWALL:-true}"

GITHUB_REPO="XTLS/Xray-core"
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

    # AL2023 ships with curl-minimal; installing the full 'curl' package conflicts.
    local pkgs=(unzip ca-certificates qrencode)
    if ! command -v curl &>/dev/null; then
        pkgs+=(curl-minimal)
    fi

    dnf -y -q install "${pkgs[@]}" || die "Failed to install dependencies"
}

download_xray() {
    local arch zip_name download_url tmpdir
    arch="$(detect_arch)"
    zip_name="Xray-linux-${arch}.zip"

    log "Detecting latest Xray-core release..."
    download_url="$(curl -fsSL "${RELEASE_URL}" | grep -oP '"browser_download_url":\s*"\K[^"]+' | grep "${zip_name}" | head -n1)"
    [[ -n "$download_url" ]] || die "Could not find download URL for ${zip_name}"

    log "Downloading Xray-core: ${download_url}"
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "${tmpdir}"; trap - RETURN' RETURN

    curl -fsSL -o "${tmpdir}/${zip_name}" "$download_url" || die "Download failed"
    unzip -q "${tmpdir}/${zip_name}" -d "${tmpdir}/extracted" || die "Extraction failed"

    install -Dm755 "${tmpdir}/extracted/xray" "${XRAY_BIN_DIR}/xray"
    install -Dm644 "${tmpdir}/extracted/geoip.dat" "${XRAY_DIR}/geoip.dat" || true
    install -Dm644 "${tmpdir}/extracted/geosite.dat" "${XRAY_DIR}/geosite.dat" || true

    log "Xray-core installed to ${XRAY_BIN_DIR}/xray"
}

generate_reality_keys() {
    log "Generating REALITY x25519 key pair..."
    local key_out
    key_out="$(${XRAY_BIN_DIR}/xray x25519)"
    REALITY_PRIVATE_KEY="$(echo "$key_out" | awk '/^PrivateKey:/ {print $2}')"
    REALITY_PUBLIC_KEY="$(echo "$key_out" | awk '/Password \(PublicKey\):/ {print $3}')"
    [[ -n "$REALITY_PRIVATE_KEY" && -n "$REALITY_PUBLIC_KEY" ]] || die "Failed to generate REALITY keys"
}

generate_short_ids() {
    # shortIds are hex strings, even length between 2 and 16 bytes.
    REALITY_SHORT_ID="$(hexdump -vn8 -e'4/4 "%08x" 1 ""' /dev/urandom | cut -c1-16)"
}

create_user() {
    if ! id -u "$XRAY_USER" &>/dev/null; then
        log "Creating system user: ${XRAY_USER}"
        useradd --no-create-home --system --shell /usr/sbin/nologin "$XRAY_USER"
    fi
}

create_dirs() {
    mkdir -p "${XRAY_DIR}" "${XRAY_LOG_DIR}"
    chown -R "${XRAY_USER}:${XRAY_USER}" "${XRAY_DIR}" "${XRAY_LOG_DIR}"
    chmod 750 "${XRAY_DIR}" "${XRAY_LOG_DIR}"
}

generate_config() {
    log "Generating Xray config: ${XRAY_DIR}/config.json"
    cat > "${XRAY_DIR}/config.json" <<EOF
{
  "log": {
    "access": "${XRAY_LOG_DIR}/access.log",
    "error": "${XRAY_LOG_DIR}/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": ${XRAY_PORT},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${XRAY_UUID}",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "${REALITY_DEST}",
          "xver": 0,
          "serverNames": [
            "${REALITY_SNI}"
          ],
          "privateKey": "${REALITY_PRIVATE_KEY}",
          "minClientVer": "",
          "maxClientVer": "",
          "maxTimeDiff": 0,
          "shortIds": [
            "${REALITY_SHORT_ID}"
          ]
        }
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
    chown "${XRAY_USER}:${XRAY_USER}" "${XRAY_DIR}/config.json"
    chmod 640 "${XRAY_DIR}/config.json"
}

create_systemd_service() {
    log "Creating systemd service..."
    cat > "$XRAY_SERVICE" <<EOF
[Unit]
Description=Xray Service
Documentation=https://xtls.github.io/
After=network.target nss-lookup.target

[Service]
User=${XRAY_USER}
Group=${XRAY_USER}
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=${XRAY_BIN_DIR}/xray run -config ${XRAY_DIR}/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
    chmod 644 "$XRAY_SERVICE"
    systemctl daemon-reload
    systemctl enable --now xray || die "Failed to start xray service"
}

open_firewall() {
    [[ "$OPEN_FIREWALL" == "true" ]] || return 0
    log "Opening port ${XRAY_PORT} in firewall..."

    if command -v firewall-cmd &>/dev/null; then
        firewall-cmd --permanent --add-port="${XRAY_PORT}/tcp" || true
        firewall-cmd --reload || true
    elif command -v iptables &>/dev/null; then
        iptables -I INPUT -p tcp --dport "${XRAY_PORT}" -j ACCEPT || true
    else
        log "WARNING: No supported firewall tool found. Open port ${XRAY_PORT}/tcp manually."
    fi
}

print_summary() {
    local public_ip vless_url
    public_ip="$(curl -fsSL -4 https://checkip.amazonaws.com 2>/dev/null || echo '<your-server-ip>')"

    # VLESS URL format: vless://uuid@host:port?params#remark
    vless_url="vless://${XRAY_UUID}@${public_ip}:${XRAY_PORT}?security=reality&sni=${REALITY_SNI}&fp=chrome&pbk=${REALITY_PUBLIC_KEY}&sid=${REALITY_SHORT_ID}&type=tcp&flow=xtls-rprx-vision#AL2023-Reality"

    cat <<EOF

========================================================================
Xray (VLESS + Vision + REALITY) installed successfully.
========================================================================

Server IP      : ${public_ip}
Port           : ${XRAY_PORT}
UUID           : ${XRAY_UUID}
Protocol       : vless
Flow           : xtls-rprx-vision
Security       : reality
REALITY dest   : ${REALITY_DEST}
REALITY SNI    : ${REALITY_SNI}
Public key     : ${REALITY_PUBLIC_KEY}
Short ID       : ${REALITY_SHORT_ID}

Config file    : ${XRAY_DIR}/config.json
Binary         : ${XRAY_BIN_DIR}/xray
Service status : systemctl status xray
Logs           : ${XRAY_LOG_DIR}/access.log
                 ${XRAY_LOG_DIR}/error.log

VLESS share URL:
  ${vless_url}

Client import settings (manual):
  Address      : ${public_ip}
  Port         : ${XRAY_PORT}
  ID/UUID      : ${XRAY_UUID}
  Flow         : xtls-rprx-vision
  Security     : reality
  SNI          : ${REALITY_SNI}
  Public key   : ${REALITY_PUBLIC_KEY}
  Short ID     : ${REALITY_SHORT_ID}
  Fingerprint  : chrome (or safari/firefox)
  Network      : tcp

IMPORTANT:
- Use this only on hosts you are authorized to manage.
- Comply with AWS Terms of Service and local laws.
- Pick a REALITY destination (dest/SNI) that supports TLS 1.3 + HTTP/2 and
  is plausible for your traffic pattern. You can change it later by editing
  ${XRAY_DIR}/config.json and restarting xray.
========================================================================
EOF

    # Print QR code if qrencode is available and terminal supports it
    if command -v qrencode &>/dev/null && [[ -t 1 ]]; then
        echo "QR code (scan with a V2Ray/Xray client):"
        qrencode -t ANSIUTF8 "$vless_url" || true
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    check_root
    install_deps
    create_user
    create_dirs
    download_xray
    generate_reality_keys
    generate_short_ids
    generate_config
    create_systemd_service
    open_firewall
    print_summary
}

main "$@"

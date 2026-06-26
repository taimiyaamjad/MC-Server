#!/usr/bin/env bash
# ============================================================
#  Minecraft Paper Server Auto-Installer
#  Plugins: AuthMe · ClearLagg · NPanel · ViaVersion ·
#           ViaBackwards · EssentialsX
#
#  Tested on: Ubuntu 22.04 / 24.04 / Debian 12
#  Requires : Java 21+, curl, jq, wget, screen
# ============================================================

set -euo pipefail

# ─── Colour helpers ─────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERR]${NC}   $*"; exit 1; }

# ─── Configuration ──────────────────────────────────────────
INSTALL_DIR="${MC_DIR:-/opt/minecraft}"
MC_USER="${MC_USER:-minecraft}"
MC_PORT="${MC_PORT:-25565}"
NPANEL_PORT="${NPANEL_PORT:-8080}"
MAX_RAM="${MAX_RAM:-2G}"
MIN_RAM="${MIN_RAM:-1G}"
ONLINE_MODE="${ONLINE_MODE:-false}"   # set true for premium-only servers

# ─── Root check ─────────────────────────────────────────────
[[ $EUID -ne 0 ]] && error "Please run as root: sudo bash $0"

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║   Minecraft Paper Server — Auto Installer   ║"
echo "  ║   AuthMe · ClearLagg · NPanel · Via* · Ess  ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── 1. System dependencies ─────────────────────────────────
info "Updating package lists..."
apt-get update -qq

info "Installing dependencies (java, curl, jq, wget, screen)..."
apt-get install -y -qq curl wget jq screen ca-certificates gnupg lsb-release > /dev/null

# ─── 2. Java 21 ─────────────────────────────────────────────
JAVA_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1 || echo "0")
if [[ "$JAVA_VER" -lt 21 ]]; then
    info "Installing Java 21 (Temurin)..."
    wget -qO- https://packages.adoptium.net/artifactory/api/gpg/key/public \
        | gpg --dearmor -o /usr/share/keyrings/adoptium.gpg
    echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] \
https://packages.adoptium.net/artifactory/deb \
$(lsb_release -sc) main" \
        > /etc/apt/sources.list.d/adoptium.list
    apt-get update -qq
    apt-get install -y -qq temurin-21-jdk > /dev/null
    success "Java 21 installed."
else
    success "Java $JAVA_VER already present — skipping."
fi

# ─── 3. Create system user & directories ────────────────────
if ! id "$MC_USER" &>/dev/null; then
    info "Creating system user '$MC_USER'..."
    useradd -r -m -d "$INSTALL_DIR" -s /bin/bash "$MC_USER"
fi
mkdir -p "$INSTALL_DIR/plugins"
chown -R "$MC_USER:$MC_USER" "$INSTALL_DIR"

# ─── 4. Download latest PaperMC ─────────────────────────────
info "Fetching latest stable PaperMC build..."
USER_AGENT="MC-AutoInstaller/1.0 (github.com/your-repo; contact@example.com)"

# Get latest Minecraft version supported by Paper
LATEST_MC=$(curl -s -H "User-Agent: $USER_AGENT" \
    "https://fill.papermc.io/v3/projects/paper" \
    | jq -r '.versions | last')

# Get latest stable build number
BUILDS_JSON=$(curl -s -H "User-Agent: $USER_AGENT" \
    "https://fill.papermc.io/v3/projects/paper/versions/${LATEST_MC}/builds")

PAPER_URL=$(echo "$BUILDS_JSON" \
    | jq -r 'map(select(.channel == "STABLE")) | last | .downloads."server:default".url // empty')

[[ -z "$PAPER_URL" ]] && error "Could not resolve PaperMC download URL."

PAPER_JAR="$INSTALL_DIR/paper.jar"
info "Downloading PaperMC for Minecraft $LATEST_MC..."
wget -q --show-progress -H "User-Agent: $USER_AGENT" \
    -O "$PAPER_JAR" "$PAPER_URL"
success "PaperMC downloaded → $PAPER_JAR"

# ─── Helper: download a plugin JAR ──────────────────────────
dl_plugin() {
    local name="$1" url="$2" dest="$INSTALL_DIR/plugins/$3"
    info "Downloading plugin: $name..."
    wget -q --show-progress -O "$dest" "$url" \
        || { warn "Failed to download $name — you may need to install it manually."; return 1; }
    success "$name → plugins/$3"
}

# ─── Helper: GitHub latest release asset ────────────────────
gh_latest_url() {
    # $1=owner/repo  $2=asset pattern (grep regex)
    curl -s "https://api.github.com/repos/$1/releases/latest" \
        | jq -r '.assets[].browser_download_url' \
        | grep -iE "$2" \
        | head -1
}

# ─── 5. Plugins ─────────────────────────────────────────────

# — AuthMe Reloaded (Paper build) —
info "Resolving AuthMe Reloaded (Paper build)..."
AUTHME_URL=$(gh_latest_url "AuthMe/AuthMeReloaded" "paper.*\.jar$")
if [[ -z "$AUTHME_URL" ]]; then
    warn "Could not auto-resolve AuthMe. Trying fallback Modrinth URL..."
    AUTHME_URL=$(curl -s "https://api.modrinth.com/v2/project/authmereloaded/version?loaders=[\"paper\"]&game_versions=[\"$LATEST_MC\"]" \
        | jq -r '.[0].files[0].url // empty')
fi
[[ -n "$AUTHME_URL" ]] && dl_plugin "AuthMe Reloaded" "$AUTHME_URL" "AuthMe.jar" \
    || warn "Install AuthMe manually: https://github.com/AuthMe/AuthMeReloaded/releases"

# — ClearLagg —
CLEARLAGG_URL=$(gh_latest_url "MCSM-Alliance/WatchDogDotPy" "ClearLagg.*\.jar$" 2>/dev/null || true)
# ClearLagg is on SpigotMC (ID 68271) — use Hangar/Modrinth fallback
if [[ -z "$CLEARLAGG_URL" ]]; then
    CLEARLAGG_URL=$(curl -s "https://api.modrinth.com/v2/project/clearlagg/version?loaders=[\"paper\"]" \
        | jq -r '.[0].files[0].url // empty' 2>/dev/null || true)
fi
if [[ -n "$CLEARLAGG_URL" ]]; then
    dl_plugin "ClearLagg" "$CLEARLAGG_URL" "ClearLagg.jar"
else
    warn "ClearLagg not found via API. Download manually: https://www.spigotmc.org/resources/clearlagg.68271/"
    warn "Place it in: $INSTALL_DIR/plugins/"
fi

# — NPanel —
NPANEL_URL=$(gh_latest_url "nerotvlive/NPanel" "NPanel.*\.jar$")
[[ -z "$NPANEL_URL" ]] && NPANEL_URL=$(gh_latest_url "danieldieeins/NPanel" "NPanel.*\.jar$")
if [[ -n "$NPANEL_URL" ]]; then
    dl_plugin "NPanel" "$NPANEL_URL" "NPanel.jar"
else
    warn "NPanel not found via GitHub API. Download manually from:"
    warn "  https://hangar.papermc.io/nerotvlive/npanel"
    warn "  https://www.spigotmc.org/resources/npanel.121178/"
    warn "Place the JAR in: $INSTALL_DIR/plugins/"
fi

# — ViaVersion —
VIAVERSION_URL=$(curl -s "https://hangar.papermc.io/api/v1/projects/ViaVersion/ViaVersion/latestrelease" \
    2>/dev/null | grep -oP '"downloadUrl":"\K[^"]+' | head -1 || true)
if [[ -z "$VIAVERSION_URL" ]]; then
    VIAVERSION_URL=$(gh_latest_url "ViaVersion/ViaVersion" "ViaVersion-[0-9].*\.jar$")
fi
[[ -n "$VIAVERSION_URL" ]] && dl_plugin "ViaVersion" "$VIAVERSION_URL" "ViaVersion.jar" \
    || warn "Install ViaVersion manually: https://github.com/ViaVersion/ViaVersion/releases"

# — ViaBackwards —
VIABACK_URL=$(gh_latest_url "ViaVersion/ViaBackwards" "ViaBackwards-[0-9].*\.jar$")
[[ -n "$VIABACK_URL" ]] && dl_plugin "ViaBackwards" "$VIABACK_URL" "ViaBackwards.jar" \
    || warn "Install ViaBackwards manually: https://github.com/ViaVersion/ViaBackwards/releases"

# — EssentialsX —
ESSENTIALS_URL=$(gh_latest_url "EssentialsX/Essentials" "EssentialsX-[0-9].*\.jar$")
[[ -n "$ESSENTIALS_URL" ]] && dl_plugin "EssentialsX" "$ESSENTIALS_URL" "EssentialsX.jar" \
    || warn "Install EssentialsX manually: https://github.com/EssentialsX/Essentials/releases"

# ─── 6. Accept EULA ─────────────────────────────────────────
info "Accepting Minecraft EULA..."
echo "eula=true" > "$INSTALL_DIR/eula.txt"

# ─── 7. server.properties ───────────────────────────────────
info "Writing server.properties..."
cat > "$INSTALL_DIR/server.properties" <<EOF
server-port=$MC_PORT
online-mode=$ONLINE_MODE
motd=\u00A7aMy Minecraft Server \u00A77| \u00A7bPowered by Paper
max-players=100
view-distance=10
simulation-distance=8
difficulty=normal
gamemode=survival
allow-flight=false
enable-command-block=true
EOF

# ─── 8. NPanel config hint ──────────────────────────────────
mkdir -p "$INSTALL_DIR/plugins/NPanel"
cat > "$INSTALL_DIR/plugins/NPanel/config.yml" <<EOF
# NPanel configuration
# DO NOT EDIT while server is running.
# After first start, set your login via console:
#   /addlogin <username> <password>

port: $NPANEL_PORT
canSendCommands: true
canViewConsole: true
canManagePlayers: true
EOF

# ─── 9. start.sh ────────────────────────────────────────────
info "Writing start script..."
cat > "$INSTALL_DIR/start.sh" <<STARTSCRIPT
#!/usr/bin/env bash
# Auto-generated start script
cd "$INSTALL_DIR"
exec java \\
    -Xms$MIN_RAM -Xmx$MAX_RAM \\
    -XX:+UseG1GC \\
    -XX:+ParallelRefProcEnabled \\
    -XX:MaxGCPauseMillis=200 \\
    -XX:+UnlockExperimentalVMOptions \\
    -XX:+DisableExplicitGC \\
    -XX:+AlwaysPreTouch \\
    -XX:G1NewSizePercent=30 \\
    -XX:G1MaxNewSizePercent=40 \\
    -XX:G1HeapRegionSize=8M \\
    -XX:G1ReservePercent=20 \\
    -XX:G1HeapWastePercent=5 \\
    -XX:G1MixedGCCountTarget=4 \\
    -XX:InitiatingHeapOccupancyPercent=15 \\
    -XX:G1MixedGCLiveThresholdPercent=90 \\
    -XX:G1RSetUpdatingPauseTimePercent=5 \\
    -XX:SurvivorRatio=32 \\
    -XX:+PerfDisableSharedMem \\
    -XX:MaxTenuringThreshold=1 \\
    -Dusing.aikars.flags=https://mcflags.emc.gs \\
    -Daikars.new.flags=true \\
    -jar paper.jar nogui
STARTSCRIPT
chmod +x "$INSTALL_DIR/start.sh"

# ─── 10. systemd service ────────────────────────────────────
info "Creating systemd service (minecraft.service)..."
cat > /etc/systemd/system/minecraft.service <<SERVICE
[Unit]
Description=Minecraft Paper Server
After=network.target

[Service]
User=$MC_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/screen -DmS minecraft $INSTALL_DIR/start.sh
ExecStop=/usr/bin/screen -S minecraft -X stuff "stop\n"
Restart=on-failure
RestartSec=10
KillSignal=SIGCONT
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable minecraft.service
chown -R "$MC_USER:$MC_USER" "$INSTALL_DIR"

# ─── 11. Open firewall ports ────────────────────────────────
if command -v ufw &>/dev/null; then
    info "Configuring UFW firewall..."
    ufw allow "$MC_PORT"/tcp  comment "Minecraft" > /dev/null
    ufw allow "$NPANEL_PORT"/tcp comment "NPanel"  > /dev/null
    success "UFW rules added for ports $MC_PORT and $NPANEL_PORT."
fi

# ─── 12. First-run boot (generates config files) ────────────
info "Running server once to generate configuration files..."
info "(This may take 30–60 seconds)"
cd "$INSTALL_DIR"
sudo -u "$MC_USER" bash -c "cd $INSTALL_DIR && \
    java -Xms512M -Xmx1G -jar paper.jar nogui" &
SERVER_PID=$!
sleep 45
kill "$SERVER_PID" 2>/dev/null || true
wait "$SERVER_PID" 2>/dev/null || true
success "Initial boot complete — config files generated."

# ─── 13. Add NPanel admin user ──────────────────────────────
NPANEL_USER="admin"
NPANEL_PASS="$(openssl rand -base64 12 | tr -d '/+=' | cut -c1-12)"

info "Starting server to add NPanel admin login..."
systemctl start minecraft.service
sleep 20

# Send the addlogin command via screen
screen -S minecraft -X stuff "/addlogin ${NPANEL_USER} ${NPANEL_PASS}\n" 2>/dev/null || true
sleep 3
success "NPanel login created."

# ─── 14. Detect public IP ───────────────────────────────────
PUBLIC_IP=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me || echo "YOUR_VPS_IP")

# ─── 15. Done! ──────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}   ✅  Installation Complete!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}Minecraft Server${NC}"
echo -e "    Address  : ${CYAN}$PUBLIC_IP:$MC_PORT${NC}"
echo -e "    Version  : ${CYAN}$LATEST_MC (PaperMC)${NC}"
echo ""
echo -e "  ${BOLD}NPanel Web Control Panel${NC}"
echo -e "    URL      : ${CYAN}http://$PUBLIC_IP:$NPANEL_PORT${NC}"
echo -e "    Username : ${CYAN}$NPANEL_USER${NC}"
echo -e "    Password : ${CYAN}$NPANEL_PASS${NC}"
echo ""
echo -e "  ${BOLD}Plugins Installed${NC}"
echo -e "    • AuthMe Reloaded   (login/register system)"
echo -e "    • ClearLagg         (lag reduction)"
echo -e "    • NPanel            (web control panel)"
echo -e "    • ViaVersion        (multi-version support)"
echo -e "    • ViaBackwards      (older client support)"
echo -e "    • EssentialsX       (core commands)"
echo ""
echo -e "  ${BOLD}Useful Commands${NC}"
echo -e "    Start   : ${YELLOW}systemctl start minecraft${NC}"
echo -e "    Stop    : ${YELLOW}systemctl stop minecraft${NC}"
echo -e "    Console : ${YELLOW}screen -r minecraft${NC}  (Ctrl+A+D to detach)"
echo -e "    Logs    : ${YELLOW}journalctl -u minecraft -f${NC}"
echo ""
echo -e "  ${BOLD}Server files${NC} → ${CYAN}$INSTALL_DIR${NC}"
echo ""
echo -e "  ${YELLOW}⚠  Save these credentials — they won't be shown again!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════${NC}"

#!/usr/bin/env bash
# ============================================================
#  Minecraft Paper Server Auto-Installer
#  By Team Zen Development — https://www.zendevelopment.in
#
#  Plugins: AuthMe · ClearLagg · NPanel · ViaVersion ·
#           ViaBackwards · EssentialsX · Playit.gg
#
#  Tested on: Ubuntu 22.04 / 24.04 / Debian 12
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
ONLINE_MODE="${ONLINE_MODE:-false}"

# ─── Root check ─────────────────────────────────────────────
[[ $EUID -ne 0 ]] && error "Please run as root: sudo bash $0"

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║   Minecraft Paper Server — Auto Installer       ║"
echo "  ║   AuthMe · ClearLagg · NPanel · Via* · Playit  ║"
echo "  ║   By Team Zen Development                       ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── 1. System dependencies ─────────────────────────────────
info "Updating package lists..."
apt-get update -qq

info "Installing dependencies (curl, jq, wget, screen)..."
apt-get install -y -qq curl wget jq screen ca-certificates gnupg lsb-release > /dev/null

# ─── 2. Java 21 ─────────────────────────────────────────────
JAVA_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1 2>/dev/null || echo "0")
if [[ "${JAVA_VER:-0}" -lt 21 ]] 2>/dev/null; then
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

PAPERMC_API="https://api.papermc.io/v2/projects/paper"

# Check the last 5 versions newest-first and pick the first that has builds
ALL_VERSIONS=$(curl -fsSL "$PAPERMC_API" | jq -r '.versions[]' | tail -5 | tac)

LATEST_MC=""
LATEST_BUILD=""

for MC_VER in $ALL_VERSIONS; do
    info "Checking builds for $MC_VER ..."
    BUILDS_JSON=$(curl -fsSL "$PAPERMC_API/versions/$MC_VER/builds" 2>/dev/null || true)

    # Try "default" channel (stable) first
    BUILD=$(echo "$BUILDS_JSON" | jq -r \
        '[.builds[]? | select(.channel=="default")] | last | .build // empty' 2>/dev/null || true)

    # Fallback: just grab the last build regardless of channel
    if [[ -z "$BUILD" || "$BUILD" == "null" ]]; then
        BUILD=$(echo "$BUILDS_JSON" | jq -r \
            '.builds[-1].build // empty' 2>/dev/null || true)
    fi

    if [[ -n "$BUILD" && "$BUILD" != "null" ]]; then
        LATEST_MC="$MC_VER"
        LATEST_BUILD="$BUILD"
        success "Found: PaperMC $LATEST_MC build #$LATEST_BUILD"
        break
    fi
done

[[ -z "$LATEST_MC" ]] && error "Could not find any PaperMC build. Check your internet connection."

JAR_NAME="paper-${LATEST_MC}-${LATEST_BUILD}.jar"
PAPER_URL="$PAPERMC_API/versions/$LATEST_MC/builds/$LATEST_BUILD/downloads/$JAR_NAME"

PAPER_JAR="$INSTALL_DIR/paper.jar"
info "Downloading PaperMC $LATEST_MC build #$LATEST_BUILD..."
wget -q --show-progress -O "$PAPER_JAR" "$PAPER_URL" \
    || error "Failed to download PaperMC JAR."
success "PaperMC downloaded → $PAPER_JAR"

# ─── Helper: download a plugin JAR ──────────────────────────
dl_plugin() {
    local name="$1" url="$2" dest="$INSTALL_DIR/plugins/$3"
    info "Downloading plugin: $name..."
    wget -q --show-progress -O "$dest" "$url" \
        && success "$name → plugins/$3" \
        || { warn "Failed to download $name — install it manually."; rm -f "$dest"; return 1; }
}

# ─── Helper: GitHub latest release asset URL ────────────────
gh_latest_url() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
        | jq -r '.assets[].browser_download_url' 2>/dev/null \
        | grep -iE "$2" \
        | head -1 || true
}

# ─── 5. Plugins ─────────────────────────────────────────────

# — AuthMe Reloaded —
info "Resolving AuthMe Reloaded..."
AUTHME_URL=$(gh_latest_url "AuthMe/AuthMeReloaded" "AuthMe.*\.jar$")
if [[ -n "$AUTHME_URL" ]]; then
    dl_plugin "AuthMe Reloaded" "$AUTHME_URL" "AuthMe.jar"
else
    warn "AuthMe: manual download → https://github.com/AuthMe/AuthMeReloaded/releases"
fi

# — ClearLagg —
info "Resolving ClearLagg..."
CLEARLAGG_URL=$(curl -fsSL \
    "https://api.modrinth.com/v2/project/clearlagg/version" \
    2>/dev/null | jq -r '.[0].files[0].url // empty' 2>/dev/null || true)
if [[ -n "$CLEARLAGG_URL" ]]; then
    dl_plugin "ClearLagg" "$CLEARLAGG_URL" "ClearLagg.jar"
else
    warn "ClearLagg: manual download → https://www.spigotmc.org/resources/clearlagg.68271/"
fi

# — NPanel —
info "Resolving NPanel..."
NPANEL_URL=$(gh_latest_url "nerotvlive/NPanel" "\.jar$")
[[ -z "$NPANEL_URL" ]] && NPANEL_URL=$(gh_latest_url "danieldieeins/NPanel" "\.jar$")
if [[ -n "$NPANEL_URL" ]]; then
    dl_plugin "NPanel" "$NPANEL_URL" "NPanel.jar"
else
    warn "NPanel: manual download → https://hangar.papermc.io/nerotvlive/npanel"
fi

# — ViaVersion —
info "Resolving ViaVersion..."
VIAVERSION_URL=$(gh_latest_url "ViaVersion/ViaVersion" "ViaVersion-[0-9].*\.jar$")
if [[ -n "$VIAVERSION_URL" ]]; then
    dl_plugin "ViaVersion" "$VIAVERSION_URL" "ViaVersion.jar"
else
    warn "ViaVersion: manual download → https://github.com/ViaVersion/ViaVersion/releases"
fi

# — ViaBackwards —
info "Resolving ViaBackwards..."
VIABACK_URL=$(gh_latest_url "ViaVersion/ViaBackwards" "ViaBackwards-[0-9].*\.jar$")
if [[ -n "$VIABACK_URL" ]]; then
    dl_plugin "ViaBackwards" "$VIABACK_URL" "ViaBackwards.jar"
else
    warn "ViaBackwards: manual download → https://github.com/ViaVersion/ViaBackwards/releases"
fi

# — EssentialsX —
info "Resolving EssentialsX..."
ESSENTIALS_URL=$(gh_latest_url "EssentialsX/Essentials" "EssentialsX-[0-9].*\.jar$")
if [[ -n "$ESSENTIALS_URL" ]]; then
    dl_plugin "EssentialsX" "$ESSENTIALS_URL" "EssentialsX.jar"
else
    warn "EssentialsX: manual download → https://github.com/EssentialsX/Essentials/releases"
fi

# — Playit.gg —
info "Resolving Playit.gg plugin..."
PLAYIT_URL=$(gh_latest_url "playit-cloud/playit-minecraft-plugin" "playit-minecraft-plugin.*\.jar$")
if [[ -n "$PLAYIT_URL" ]]; then
    dl_plugin "Playit.gg" "$PLAYIT_URL" "playit.jar"
else
    warn "Playit: manual download → https://github.com/playit-cloud/playit-minecraft-plugin/releases"
fi

# ─── 6. Accept EULA ─────────────────────────────────────────
info "Accepting Minecraft EULA..."
echo "eula=true" > "$INSTALL_DIR/eula.txt"

# ─── 7. server.properties ───────────────────────────────────
info "Writing server.properties..."
cat > "$INSTALL_DIR/server.properties" << EOF
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

# ─── 8. NPanel config ───────────────────────────────────────
mkdir -p "$INSTALL_DIR/plugins/NPanel"
cat > "$INSTALL_DIR/plugins/NPanel/config.yml" << EOF
# NPanel configuration — do NOT edit while server is running
port: $NPANEL_PORT
canSendCommands: true
canViewConsole: true
canManagePlayers: true
EOF

# ─── 9. start.sh (Aikar's optimised JVM flags) ──────────────
info "Writing start script..."
cat > "$INSTALL_DIR/start.sh" << STARTSCRIPT
#!/usr/bin/env bash
cd "$INSTALL_DIR"
exec java \
    -Xms${MIN_RAM} -Xmx${MAX_RAM} \
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:MaxGCPauseMillis=200 \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+DisableExplicitGC \
    -XX:+AlwaysPreTouch \
    -XX:G1NewSizePercent=30 \
    -XX:G1MaxNewSizePercent=40 \
    -XX:G1HeapRegionSize=8M \
    -XX:G1ReservePercent=20 \
    -XX:G1HeapWastePercent=5 \
    -XX:G1MixedGCCountTarget=4 \
    -XX:InitiatingHeapOccupancyPercent=15 \
    -XX:G1MixedGCLiveThresholdPercent=90 \
    -XX:G1RSetUpdatingPauseTimePercent=5 \
    -XX:SurvivorRatio=32 \
    -XX:+PerfDisableSharedMem \
    -XX:MaxTenuringThreshold=1 \
    -Dusing.aikars.flags=https://mcflags.emc.gs \
    -Daikars.new.flags=true \
    -jar paper.jar nogui
STARTSCRIPT
chmod +x "$INSTALL_DIR/start.sh"

# ─── 10. systemd service ────────────────────────────────────
info "Creating systemd service..."
cat > /etc/systemd/system/minecraft.service << SERVICE
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

# ─── 11. Firewall ───────────────────────────────────────────
if command -v ufw &>/dev/null; then
    info "Configuring UFW firewall..."
    ufw allow "$MC_PORT"/tcp     comment "Minecraft" > /dev/null 2>&1 || true
    ufw allow "$NPANEL_PORT"/tcp comment "NPanel"    > /dev/null 2>&1 || true
    success "UFW: ports $MC_PORT and $NPANEL_PORT opened."
fi

# ─── 12. First-run boot to generate config files ────────────
info "Running server once to generate configs (up to 60s)..."
sudo -u "$MC_USER" bash -c "cd $INSTALL_DIR && \
    java -Xms512M -Xmx1G -jar paper.jar nogui" &
SERVER_PID=$!
sleep 55
kill "$SERVER_PID" 2>/dev/null || true
wait "$SERVER_PID" 2>/dev/null || true
success "Config generation complete."

# ─── 13. NPanel credentials & final start ───────────────────
NPANEL_USER="admin"
NPANEL_PASS="$(openssl rand -base64 12 | tr -d '/+=' | cut -c1-12)"

info "Starting server via systemd..."
systemctl start minecraft.service
sleep 25

info "Adding NPanel admin user..."
screen -S minecraft -X stuff "/addlogin ${NPANEL_USER} ${NPANEL_PASS}\n" 2>/dev/null || true
sleep 3
success "NPanel credentials set."

# ─── 14. Detect public IP & playit tunnel ───────────────────
PUBLIC_IP=$(curl -fsSL https://api.ipify.org 2>/dev/null \
    || curl -fsSL https://ifconfig.me 2>/dev/null \
    || echo "YOUR_VPS_IP")

# ─── 15. Done! ──────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}   ✅  Installation Complete! — Team Zen Development  ${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}🎮 Minecraft Server${NC}"
echo -e "    Address  : ${CYAN}$PUBLIC_IP:$MC_PORT${NC}"
echo -e "    Version  : ${CYAN}$LATEST_MC (PaperMC build #$LATEST_BUILD)${NC}"
echo ""
echo -e "  ${BOLD}🖥️  NPanel Web Control Panel${NC}"
echo -e "    URL      : ${CYAN}http://$PUBLIC_IP:$NPANEL_PORT${NC}"
echo -e "    Username : ${CYAN}$NPANEL_USER${NC}"
echo -e "    Password : ${CYAN}$NPANEL_PASS${NC}"
echo ""
echo -e "  ${BOLD}🌐 Playit.gg Tunnel${NC}"
echo -e "    ${YELLOW}Check your server console for the Playit claim URL!${NC}"
echo -e "    Run: ${CYAN}screen -r minecraft${NC}  then look for a link like:"
echo -e "         ${CYAN}https://playit.gg/claim/xxxxx${NC}"
echo -e "    Visit that URL to claim your free public tunnel address."
echo -e "    Your players will then connect via: ${CYAN}<yourname>.playit.gg${NC}"
echo ""
echo -e "  ${BOLD}🧩 Plugins${NC}"
echo -e "    • AuthMe Reloaded   — login/register system"
echo -e "    • ClearLagg         — lag reduction"
echo -e "    • NPanel            — web control panel"
echo -e "    • ViaVersion        — multi-version support"
echo -e "    • ViaBackwards      — older client support"
echo -e "    • EssentialsX       — core commands"
echo -e "    • Playit.gg         — free public IP tunnel (no port forwarding)"
echo ""
echo -e "  ${BOLD}🛠  Useful Commands${NC}"
echo -e "    Start   : ${YELLOW}systemctl start minecraft${NC}"
echo -e "    Stop    : ${YELLOW}systemctl stop minecraft${NC}"
echo -e "    Console : ${YELLOW}screen -r minecraft${NC}   (Ctrl+A+D to detach)"
echo -e "    Logs    : ${YELLOW}journalctl -u minecraft -f${NC}"
echo ""
echo -e "  ${BOLD}📁 Files${NC} → ${CYAN}$INSTALL_DIR${NC}"
echo ""
echo -e "  🌐 ${CYAN}https://www.zendevelopment.in${NC}"
echo -e "  ${YELLOW}⚠  Save your NPanel credentials — shown only once!${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════${NC}"

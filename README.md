<div align="center">

<img src="https://img.shields.io/badge/Minecraft-Paper%201.21%2B-brightgreen?style=for-the-badge&logo=minecraft&logoColor=white"/>
<img src="https://img.shields.io/badge/Java-21%2B-orange?style=for-the-badge&logo=openjdk&logoColor=white"/>
<img src="https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-blue?style=for-the-badge&logo=linux&logoColor=white"/>
<img src="https://img.shields.io/badge/Playit.gg-Tunnel%20Ready-blueviolet?style=for-the-badge"/>
<img src="https://img.shields.io/badge/No%20systemctl-screen%20%2B%20cron-success?style=for-the-badge"/>
<img src="https://img.shields.io/badge/License-MIT-purple?style=for-the-badge"/>

# 🎮 MC-Server Auto Installer

**A one-command Minecraft Paper server installer for any VPS**
*Complete with web control panel, public tunnel IP, and essential plugins — ready in minutes.*
*No systemctl required — works on any Linux VPS!*

<br/>

> Created & maintained by **[Team Zen Development](https://www.zendevelopment.in)**
> 🌐 [www.zendevelopment.in](https://www.zendevelopment.in)

</div>

---

## ✨ What It Does

This single bash script sets up a **production-ready Minecraft Paper server** on any fresh Ubuntu or Debian VPS. No manual configuration needed — just run it and you'll get:

- ✅ Latest **PaperMC** (auto-fetched from the official API)
- ✅ **NPanel** web control panel accessible in your browser
- ✅ **Playit.gg** plugin — gives your server a free public IP with no port forwarding
- ✅ All plugins pre-installed & auto-downloaded via GitHub/Modrinth APIs
- ✅ Optimized JVM flags (Aikar's flags)
- ✅ **No systemctl needed** — runs via `screen` + `crontab` (works on any VPS)
- ✅ Auto-restarts on reboot via crontab
- ✅ Simple `mc.sh` control script — start, stop, restart, logs in one command

---

## 🧩 Plugins Included

| Plugin | Purpose |
|---|---|
| 🔐 **AuthMe Reloaded** | Login/register system — protects offline-mode servers |
| 🧹 **ClearLagg** | Reduces server lag by clearing entities & dropped items |
| 🖥️ **NPanel** | In-browser web control panel — no extra software needed |
| 🔀 **ViaVersion** | Lets newer clients connect to your server version |
| ⬅️ **ViaBackwards** | Lets older clients connect to your server version |
| ⚙️ **EssentialsX** | Core commands: `/home`, `/spawn`, `/tp`, `/warp` and more |
| 🌐 **Playit.gg** | Free public tunnel — gives your server a permanent IP address |

---

## 🚀 Quick Start

### Requirements
- Ubuntu 22.04 / 24.04 or Debian 12
- Root or sudo access
- At least **2 GB RAM** (4 GB recommended)
- **No systemctl required!**

### One-Line Install

```bash
wget -O install.sh https://raw.githubusercontent.com/taimiyaamjad/MC-Server/main/install-mc-server.sh && sudo bash install.sh
```

Or for Without Sudo:

```bash
wget -O install.sh https://raw.githubusercontent.com/taimiyaamjad/MC-Server/main/install-mc-server.sh && sudo bash root.sh
```

Or clone and run:

```bash
git clone https://github.com/taimiyaamjad/MC-Server.git
cd MC-Server
sudo bash install-mc-server.sh
```

---

## ⚙️ Configuration Options

Set environment variables **before** running to customise the install:

```bash
export MC_PORT=25565        # Minecraft server port (default: 25565)
export NPANEL_PORT=8080     # NPanel web panel port (default: 8080)
export MAX_RAM=4G           # Maximum RAM (default: 2G)
export MIN_RAM=1G           # Minimum RAM (default: 1G)
export ONLINE_MODE=false    # true = premium players only (default: false)

sudo bash install-mc-server.sh
```

---

## 🛠️ Managing Your Server

The script creates a simple `mc.sh` control script — **no systemctl needed**.

```bash
cd /opt/minecraft

./mc.sh start      # Start the server
./mc.sh stop       # Stop the server
./mc.sh restart    # Restart the server
./mc.sh status     # Check if server is running
./mc.sh console    # Attach to live console  (Ctrl+A then D to detach)
./mc.sh logs       # Follow live server logs
```

The server also **auto-starts on reboot** via a crontab entry added automatically during install.

---

## 🌐 Playit.gg — Free Public IP

No port forwarding? No problem. **Playit.gg** creates a permanent public tunnel address so anyone can join from anywhere — for free.

**How to activate after install:**

1. Open the server console:
   ```bash
   cd /opt/minecraft && ./mc.sh console
   ```
2. Look for a claim URL printed automatically on startup:
   ```
   https://playit.gg/claim/xxxxxxxxxxxxxxxx
   ```
3. Visit that link, sign in (free account), and your tunnel activates
4. Your players connect using your assigned address e.g. `yourserver.playit.gg`

> 💡 The tunnel address is **permanent and static** — it won't change when you restart.

---

## 🖥️ NPanel Web Control Panel

Manage your server from any browser — no PHP, no external web server needed.

```
http://YOUR_VPS_IP:8080
```

Your **auto-generated credentials** are printed at the end of the install. You can also manage users via console:

```
/addlogin <username> <password>   → Add a panel user
/passwd <username> <old> <new>    → Change a user's password
```

> ⚠️ **NPanel requires Java 21+** and is currently in **beta**. Save your credentials — shown only once!

---

## 📁 File Structure

```
/opt/minecraft/
├── paper.jar              ← PaperMC server
├── start.sh               ← Raw startup script
├── stop.sh                ← Raw stop script
├── mc.sh                  ← Master control: start/stop/restart/console/logs
├── eula.txt               ← Auto-accepted EULA
├── server.properties      ← Server configuration
└── plugins/
    ├── AuthMe.jar
    ├── ClearLagg.jar
    ├── NPanel.jar
    ├── ViaVersion.jar
    ├── ViaBackwards.jar
    ├── EssentialsX.jar
    ├── playit.jar
    └── NPanel/
        └── config.yml
```

---

## 🔒 Ports Used

| Port | Service |
|---|---|
| `25565` | Minecraft game server |
| `8080` | NPanel web control panel |

> If you're using Playit.gg, players connect via your tunnel address — **no need to expose port 25565** at all!

---

## ❓ Troubleshooting

**Server won't start?**
```bash
cd /opt/minecraft && ./mc.sh logs
```

**NPanel not loading?**
```bash
ufw allow 8080/tcp
```

**Playit claim URL not showing?**
Open the console (`./mc.sh console`) and wait 10–20 seconds after startup.

**Plugin didn't download?**
Some plugins may hit GitHub API rate limits. Check install output warnings and manually drop the JAR into `/opt/minecraft/plugins/`, then run `./mc.sh restart`.

**ClearLagg not found?**
Download manually from [SpigotMC](https://www.spigotmc.org/resources/clearlagg.68271/) and place in `/opt/minecraft/plugins/`.

**Server not starting on reboot?**
Check crontab: `crontab -l` — you should see a `@reboot` line for minecraft.

---

## 📄 License

This project is licensed under the **MIT License** — free to use, modify, and distribute.

---

<div align="center">

## 👥 About Team Zen Development

This project was built and is maintained by **Team Zen Development** — a team passionate about making server infrastructure simple and accessible for everyone.

🌐 **Website:** [www.zendevelopment.in](https://www.zendevelopment.in)

---

*If this saved you time, give the repo a ⭐ star!*

</div>

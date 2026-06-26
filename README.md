<div align="center">

<img src="https://img.shields.io/badge/Minecraft-Paper%201.21%2B-brightgreen?style=for-the-badge&logo=minecraft&logoColor=white"/>
<img src="https://img.shields.io/badge/Java-21%2B-orange?style=for-the-badge&logo=openjdk&logoColor=white"/>
<img src="https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-blue?style=for-the-badge&logo=linux&logoColor=white"/>
<img src="https://img.shields.io/badge/Playit.gg-Tunnel%20Ready-blueviolet?style=for-the-badge"/>
<img src="https://img.shields.io/badge/License-MIT-purple?style=for-the-badge"/>

# 🎮 MC-Server Auto Installer

**A one-command Minecraft Paper server installer for any VPS**
*Complete with web control panel, public tunnel IP, and essential plugins — ready in minutes.*

<br/>

> Created & maintained by **[Team Zen Development](https://www.zendevelopment.in)**
> 🌐 [www.zendevelopment.in](https://www.zendevelopment.in)

</div>

---

## ✨ What It Does

This single bash script sets up a **production-ready Minecraft Paper server** on any fresh Ubuntu or Debian VPS. No manual configuration needed — just run it and you'll get:

- ✅ Latest **PaperMC** (auto-fetched from the official API)
- ✅ **NPanel** web control panel accessible in your browser
- ✅ **Playit.gg** tunnel — gives your server a free public IP with no port forwarding
- ✅ Essential plugins pre-installed & auto-downloaded
- ✅ Optimized JVM flags (Aikar's flags)
- ✅ systemd service (auto-restart on reboot)
- ✅ Firewall rules configured automatically

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

### One-Line Install

```bash
wget -O install.sh https://raw.githubusercontent.com/taimiyaamjad/MC-Server/main/install-mc-server.sh && sudo bash install.sh
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

## 🌐 Playit.gg — Free Public IP Tunnel

No port forwarding? No problem. **Playit.gg** creates a permanent public tunnel address for your server so anyone can join from anywhere.

**How it works after install:**

1. Start your server: `systemctl start minecraft`
2. Open the console: `screen -r minecraft`
3. Look for a claim URL that appears in the console:
   ```
   https://playit.gg/claim/xxxxxxxxxxxxxxxx
   ```
4. Visit that link, sign in (free), and your tunnel is activated
5. Your players connect using your assigned address, e.g. `yourserver.playit.gg`

> 💡 The tunnel address is **permanent and static** — it won't change when you restart your server.

---

## 🖥️ NPanel Web Control Panel

Manage your server from any browser — no PHP, no external web server needed.

```
http://YOUR_VPS_IP:8080
```

Your **auto-generated credentials** are printed at the end of the install. You can also manage users via the in-game/console commands:

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
├── start.sh               ← Optimized startup script
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

## 🛠️ Managing Your Server

| Action | Command |
|---|---|
| Start server | `systemctl start minecraft` |
| Stop server | `systemctl stop minecraft` |
| Restart server | `systemctl restart minecraft` |
| Enable on boot | `systemctl enable minecraft` |
| View live console | `screen -r minecraft` |
| Detach from console | `Ctrl + A`, then `D` |
| View logs | `journalctl -u minecraft -f` |

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
Check logs: `journalctl -u minecraft -n 50`

**NPanel not loading?**
Make sure port 8080 is open: `ufw allow 8080/tcp`

**Playit claim URL not showing?**
Open the console (`screen -r minecraft`) and wait 10–20 seconds after startup. The URL appears automatically.

**Plugin didn't download?**
Some plugins may need manual download if the GitHub API rate-limits. Check install output warnings and drop the JAR into `/opt/minecraft/plugins/`, then restart the server.

**ClearLagg not found?**
Download it manually from [SpigotMC](https://www.spigotmc.org/resources/clearlagg.68271/) and place it in `/opt/minecraft/plugins/`.

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

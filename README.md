<div align="center">

<img src="https://img.shields.io/badge/Minecraft-Paper%201.21%2B-brightgreen?style=for-the-badge&logo=minecraft&logoColor=white"/>
<img src="https://img.shields.io/badge/Java-21%2B-orange?style=for-the-badge&logo=openjdk&logoColor=white"/>
<img src="https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-blue?style=for-the-badge&logo=linux&logoColor=white"/>
<img src="https://img.shields.io/badge/License-MIT-purple?style=for-the-badge"/>

# 🎮 MC-Server Auto Installer

**A one-command Minecraft Paper server installer for any VPS**
*Complete with web control panel and essential plugins — ready in minutes.*

<br/>

> Created & maintained by **[Team Zen Development](https://www.zendevelopment.in)**
> 🌐 [www.zendevelopment.in](https://www.zendevelopment.in)

</div>

---

## ✨ What It Does

This single bash script sets up a **production-ready Minecraft Paper server** on any fresh Ubuntu or Debian VPS. No manual configuration needed — just run it and you'll get:

- ✅ Latest **PaperMC** (auto-fetched from the official API)
- ✅ **NPanel** web control panel accessible in your browser
- ✅ Essential plugins pre-installed
- ✅ Optimized JVM flags (Aikar's flags)
- ✅ systemd service (auto-restart on reboot)
- ✅ Firewall rules configured automatically

---

## 🧩 Plugins Included

| Plugin | Purpose |
|---|---|
| 🔐 **AuthMe Reloaded** | Login/register system — protects offline-mode servers |
| 🧹 **ClearLagg** | Reduces server lag by clearing entities & items |
| 🖥️ **NPanel** | In-browser web control panel — no extra software needed |
| 🔀 **ViaVersion** | Lets newer clients connect to your server |
| ⬅️ **ViaBackwards** | Lets older clients connect to your server |
| ⚙️ **EssentialsX** | Core commands: `/home`, `/spawn`, `/tp`, `/warp` and more |

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

Or if you've already cloned the repo:

```bash
git clone https://github.com/taimiyaamjad/MC-Server.git
cd MC-Server
sudo bash install-mc-server.sh
```

---

## ⚙️ Configuration Options

You can customize the installation by setting environment variables **before** running the script:

```bash
export MC_PORT=25565        # Minecraft server port (default: 25565)
export NPANEL_PORT=8080     # NPanel web panel port (default: 8080)
export MAX_RAM=4G           # Maximum RAM for the server (default: 2G)
export MIN_RAM=1G           # Minimum RAM (default: 1G)
export ONLINE_MODE=false    # true = premium players only (default: false)

sudo bash install-mc-server.sh
```

---

## 🖥️ NPanel Web Control Panel

After installation, NPanel is accessible directly in your browser — no extra web server or PHP required.

```
http://YOUR_VPS_IP:8080
```

Your **auto-generated credentials** are displayed at the end of the install. You can also manage users via console:

```
/addlogin <username> <password>   → Add a panel user
/passwd <username> <old> <new>    → Change a user's password
```

> ⚠️ **NPanel requires Java 21+** and is currently in **beta**. Save your credentials — they're only shown once.

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

Make sure these ports are open in your VPS provider's firewall/security group settings as well.

---

## ❓ Troubleshooting

**Server won't start?**
Check logs: `journalctl -u minecraft -n 50`

**NPanel not loading?**
Make sure port 8080 is open: `ufw allow 8080/tcp`

**Plugin didn't download?**
Some plugins may need to be downloaded manually if the GitHub API rate-limits. Check the warnings in the install output and drop the JAR into `/opt/minecraft/plugins/`.

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

*If this saved you time, consider giving the repo a ⭐ star!*

</div>

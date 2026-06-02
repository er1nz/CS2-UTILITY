# **CS2 UTILITY - [@er1nz](https://www.github.com/er1nz)**

**CS2 Utility - Advanced optimization script for Counter-Strike 2, featuring automatic installation detection, cache cleaning, DirectX/NVIDIA optimization, Steam Cloud management, network tweaks, and comprehensive system maintenance tools.**

## 🆕 What's New in v0.0.4 (June 2026)

### ⭐ Major Features
- **🌩️ Deep Clean Steam Cloud** - NEW advanced feature to reset Steam Cloud to factory state, removing legacy CS:GO configs and accumulated bloat that causes frame drops and input lag
- **🔄 Updated Launch Parameters** - Optimized settings for 2026 systems
- **⚡ Enhanced Steam Tweaks** - Improved performance optimization with NoSteamWebHelper v5.0.2 integration
- **🐛 Bug Fixes** - Fixed infinite loop issues, improved error handling, added non-interactive mode protection

### 🎯 Core Features
1. **Clear DirectX Shader Cache** - Remove accumulated shader compilation cache
2. **Clear NVIDIA DXCache** - Clean NVIDIA's DirectX cache files
3. **Steam Console Integration** - Launch console and send shader_build command (730)
4. **Autoexec Configuration** - Add optimized autoexec.cfg automatically
5. **Launch Parameters** - Configure optimal CS2 startup parameters
6. **Steam Performance Tweaks** - Disable unnecessary Steam features, integrate NoSteamWebHelper
7. **Network Optimization** - Windows 10/11 specific network tweaks (⚠️ Disables IPv6)
8. **System Integrity Check** - Scan and repair system corruption (SFC/DISM)
9. **CS2 Auto-Detection** - Automatically locate CS2 installation across multiple drives
10. **Deep Clean Steam Cloud** - Reset Steam Cloud to eliminate performance issues from legacy configs

## 🔗 Links
- [![telegram](https://img.shields.io/badge/Telegram-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/qqer1nz)
- **https://guns.lol/er1nz**

## 📥 Installation

1. Download the latest `cs2utility.bat` from [Releases](https://github.com/er1nz/CS2-UTILITY/releases)
2. Right-click and select **"Run as Administrator"**
3. Follow the on-screen menu

**⚠️ Important:** Always run options 1-3 after every CS2 game update for optimal performance.

## 🛠️ Technical Details

### Automatic CS2 Detection
The script automatically detects CS2 installation by:
- Checking Windows Registry for Steam installation
- Parsing Steam library configuration files
- Scanning multiple drives for CS2 directories
- Validating CS2 directory structure

### Deep Clean Steam Cloud Feature
**What it does:**
- Backs up current configuration
- Force-closes Steam process
- Removes local CS2 config files
- Clears Steam Cloud remotecache
- Triggers fresh cloud synchronization

**Why it helps:**
Over time, Steam Cloud accumulates:
- Outdated CS:GO settings that conflict with CS2
- Workshop cache and temporary files
- Conflicting console variables (cvars)

This causes frame time spikes, input delay, and unstable performance. The deep clean procedure emulates a "fresh account" experience without losing your inventory or transaction history.

**⚠️ Advanced Users Only:** This feature creates a backup before proceeding and requires Steam to be closed.

### Network Tweaks
Optimizes Windows network stack for gaming:
- TCP/IP parameter tuning
- Network adapter configuration for minimum latency
- **Note:** Disables IPv6 - ensure this is acceptable for your network setup

### System Requirements
- Windows 10/11
- Administrator privileges
- Counter-Strike 2 installed via Steam

## 📊 Version History

### v0.0.4 (June 2026) - Current
- ✨ NEW: Deep Clean Steam Cloud feature
- 🔄 Updated launch parameters and Steam tweaks
- 🐛 Fixed infinite loop in non-interactive mode
- 🗑️ Removed non-functional cs2.ini option
- 📈 File size: 99,374 bytes (+20KB from v0.0.3)
- 📝 Added ~562 lines of code

### v0.0.3 (July 2025)
- Added Steam optimization section
- Integrated NoSteamWebHelper
- Added network optimization features
- Added system integrity checker
- Improved launch parameters

### v0.0.2 (May 2025)
- Enhanced UI with professional formatting
- Automatic CS2 installation detection
- Comprehensive error handling
- Advanced file operations with validation
- 6x larger codebase with modular architecture

### v0.0.1 (May 2025)
- Initial release
- Basic cache cleaning functionality
- Manual path input
- Core optimization features

## ⚠️ Important Notes

1. **NoSteamWebHelper Compatibility:** Last working version is v5.0.2 (December 2025)
2. **IPv6 Warning:** Network tweaks option disables IPv6 protocol
3. **Admin Rights Required:** Script must be run as Administrator for registry/system modifications
4. **Backup Recommended:** Deep Clean Steam Cloud creates automatic backups, but manual backups are still recommended

## 🤝 Credit
* Made by [er1nz](https://github.com/er1nz) for maxxed out CS2 performance. [Join my Telegram channel!](https://t.me/qqer1nz)
* Network Tweaker by [Ancel](https://github.com/ancel1x/Ancels-Performance-Batch) from his Windows Performance Batch
* Corruption Checker by [Falcon Tweaks](https://discord.gg/7hAUNJNPK7)
* Inspiration from [Fortnite Utility](https://github.com/arsenzaaa/FORTNITE-UTILITY) by [@arsenza](https://github.com/arsenzaaa)

## 📜 License

This project is provided as-is for educational and optimization purposes. Use at your own risk. Always create backups before modifying system settings.

---

![Logo](https://github.com/er1nz/CS2-UTILITY/blob/main/CS2.png?raw=true)

**⭐ Star this repository if CS2 Utility helped improve your performance!**

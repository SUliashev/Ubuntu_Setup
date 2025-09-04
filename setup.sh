#!/bin/bash

# -------------------------------
# Safe setup script for Ubuntu
# -------------------------------

# Prevent script from stopping entirely on errors in specific sections
set -e

# -------------------------------
# Variables
# -------------------------------
INSTALLED_APPS=()
SKIPPED_APPS=()
FAILED_APPS=()
INSTALLED_EXTENSIONS=()
SKIPPED_EXTENSIONS=()
FAILED_EXTENSIONS=()
FAILED_UPDATES=()

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
RED="\033[0;31m"
NC="\033[0m"

# -------------------------------
# Helper functions
# -------------------------------
safe_apt_install() {
    if dpkg -s "$1" &> /dev/null; then
        SKIPPED_APPS+=("$1")
    else
        if sudo apt install -y "$1"; then
            INSTALLED_APPS+=("$1")
        else
            FAILED_APPS+=("$1")
        fi
    fi
}

safe_extension_install() {
    if code --list-extensions | grep -q "^$1$"; then
        SKIPPED_EXTENSIONS+=("$1")
    else
        if code --install-extension "$1"; then
            INSTALLED_EXTENSIONS+=("$1")
        else
            FAILED_EXTENSIONS+=("$1")
        fi
    fi
}

safe_update() {
    if ! sudo apt upgrade -y; then
        FAILED_UPDATES+=("Some packages failed to update")
    fi
}

# -------------------------------
# 1. Update system
# -------------------------------
echo -e "${BLUE}🔄 Updating system...${NC}"
sudo apt update
safe_update

# -------------------------------
# 2. Essentials
# -------------------------------
echo -e "${BLUE}📦 Installing essential packages...${NC}"
ESSENTIALS=(git curl wget python3 python3-pip build-essential apt-transport-https software-properties-common)
for app in "${ESSENTIALS[@]}"; do
    safe_apt_install "$app"
done

# -------------------------------
# 3. Add repositories
# -------------------------------
echo -e "${BLUE}🔧 Adding repositories...${NC}"

# Google Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-linux-signing.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

# Opera (modern key method)
if curl -fsSL https://deb.opera.com/archive.key | gpg --dearmor | sudo tee /usr/share/keyrings/opera.gpg > /dev/null; then
    echo "deb [signed-by=/usr/share/keyrings/opera.gpg] https://deb.opera.com/opera-stable/ stable non-free" | sudo tee /etc/apt/sources.list.d/opera.list
else
    echo -e "${RED}⚠️ Opera key failed, skipping Opera repo${NC}"
    FAILED_APPS+=("Opera repo key download failed")
fi

# Spotify
if curl -fsSL https://download.spotify.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/spotify.gpg > /dev/null; then
    echo "deb [signed-by=/usr/share/keyrings/spotify.gpg] http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
else
    FAILED_APPS+=("Spotify repo key download failed")
fi

# VS Code
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/packages.microsoft.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list

sudo apt update

# -------------------------------
# 4. Install main applications
# -------------------------------
echo -e "${BLUE}📦 Installing main applications...${NC}"
MAIN_APPS=(telegram-desktop code google-chrome-stable opera-stable spotify-client)
for app in "${MAIN_APPS[@]}"; do
    safe_apt_install "$app"
done

# -------------------------------
# 5. Keyboard Shortcuts (Pop!_OS style)
# -------------------------------
echo -e "${BLUE}🔧 Applying keyboard shortcuts...${NC}"
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Alt>grave']"
gsettings set org.gnome.desktop.wm.keybindings switch-group-backward "['<Shift><Alt>grave']"

# -------------------------------
# 6. Restore VS Code Extensions
# -------------------------------
echo -e "${BLUE}📦 Restoring VS Code extensions...${NC}"
if [ ! -f vscode-extensions.txt ]; then
    if ! curl -fsSL -O https://raw.githubusercontent.com/SUliashev/Ubuntu_Setup/main/vscode-extensions.txt; then
        FAILED_EXTENSIONS+=("vscode-extensions.txt download failed")
    fi
fi

if [ -f vscode-extensions.txt ]; then
    while read ext; do
        safe_extension_install "$ext"
    done < vscode-extensions.txt
fi

# -------------------------------
# 7. Summary
# -------------------------------
echo -e "${BLUE}--------------------------------${NC}"
echo -e "${BLUE}🎉 Setup Summary:${NC}"
echo ""
echo -e "${GREEN}✅ Applications installed:${NC} ${INSTALLED_APPS[*]}"
echo -e "${YELLOW}⚪ Applications skipped:${NC} ${SKIPPED_APPS[*]}"
if [ ${#FAILED_APPS[@]} -ne 0 ]; then
    echo -e "${RED}❌ Applications failed:${NC} ${FAILED_APPS[*]}"
fi
echo ""
if [ ${#FAILED_UPDATES[@]} -ne 0 ]; then
    echo -e "${RED}❌ Failed updates:${NC} ${FAILED_UPDATES[*]}"
else
    echo -e "${BLUE}🔄 System updates applied successfully${NC}"
fi
echo ""
echo -e "${GREEN}✅ VS Code extensions installed:${NC} ${INSTALLED_EXTENSIONS[*]}"
echo -e "${YELLOW}⚪ VS Code extensions skipped:${NC} ${SKIPPED_EXTENSIONS[*]}"
if [ ${#FAILED_EXTENSIONS[@]} -ne 0 ]; then
    echo -e "${RED}❌ VS Code extensions failed:${NC} ${FAILED_EXTENSIONS[*]}"
fi
echo -e "${BLUE}--------------------------------${NC}"
echo -e "${GREEN}🎉 Setup complete! Please reboot for all changes to apply.${NC}"


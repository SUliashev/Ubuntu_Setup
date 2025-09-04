#!/bin/bash
set -e

echo "🚀 Starting Ubuntu setup..."

# -------------------------------
# 1. Update system
# -------------------------------
echo "🔄 Updating system..."
sudo apt update
sudo apt upgrade -y

# Get list of upgraded packages for summary
UPGRADED=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | awk -F/ '{print $1}')

# -------------------------------
# 2. Essentials
# -------------------------------
echo "📦 Installing essential packages..."
ESSENTIALS=(git curl wget python3 python3-pip build-essential apt-transport-https software-properties-common)
INSTALLED_APPS=()
SKIPPED_APPS=()

install_app() {
    if dpkg -s "$1" &> /dev/null; then
        SKIPPED_APPS+=("$1")
    else
        sudo apt install -y "$1"
        INSTALLED_APPS+=("$1")
    fi
}

for app in "${ESSENTIALS[@]}"; do
    install_app "$app"
done

# -------------------------------
# 3. Add Repositories (Chrome, Opera, Spotify, VS Code)
# -------------------------------
echo "🔧 Adding repositories..."
# Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
# Opera
wget -qO- https://deb.opera.com/archive.key | sudo apt-key add -
sudo add-apt-repository -y "deb https://deb.opera.com/opera-stable/ stable non-free"
# Spotify
curl -sS https://download.spotify.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
# VS Code
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg

sudo apt update

# -------------------------------
# 4. Install Applications
# -------------------------------
echo "📦 Installing main applications..."
MAIN_APPS=(telegram-desktop code google-chrome-stable opera-stable spotify-client)
for app in "${MAIN_APPS[@]}"; do
    install_app "$app"
done

# -------------------------------
# 5. Keyboard Shortcuts (Pop!_OS style)
# -------------------------------
echo "🔧 Applying keyboard shortcuts..."
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Alt>grave']"
gsettings set org.gnome.desktop.wm.keybindings switch-group-backward "['<Shift><Alt>grave']"

# -------------------------------
# 6. Restore VS Code Extensions
# -------------------------------
echo "📦 Restoring VS Code extensions..."
if [ ! -f vscode-extensions.txt ]; then
    curl -O https://raw.githubusercontent.com/SUliashev/Ubuntu_Setup/main/vscode-extensions.txt
fi

INSTALLED_EXTENSIONS=()
SKIPPED_EXTENSIONS=()
if [ -f vscode-extensions.txt ]; then
    while read ext; do
        if code --list-extensions | grep -q "^$ext$"; then
            SKIPPED_EXTENSIONS+=("$ext")
        else
            code --install-extension "$ext"
            INSTALLED_EXTENSIONS+=("$ext")
        fi
    done < vscode-extensions.txt
fi

# -------------------------------
# 7. Summary with colors
# -------------------------------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

echo "--------------------------------"
echo -e "${BLUE}🎉 Setup Summary:${NC}"
echo ""

# Applications
echo -e "${GREEN}✅ Applications installed:${NC} ${INSTALLED_APPS[*]}"
echo -e "${YELLOW}⚪ Applications skipped:${NC} ${SKIPPED_APPS[*]}"

# System updates
if [ -n "$UPGRADED" ]; then
    echo -e "${BLUE}🔄 System packages updated:${NC}"
    echo "$UPGRADED"
else
    echo -e "${YELLOW}⚪ No system packages needed updating${NC}"
fi

# VS Code extensions
echo -e "${GREEN}✅ VS Code extensions installed:${NC} ${INSTALLED_EXTENSIONS[*]}"
echo -e "${YELLOW}⚪ VS Code extensions skipped:${NC} ${SKIPPED_EXTENSIONS[*]}"
echo "--------------------------------"
echo -e "${GREEN}🎉 Setup complete! Please reboot for all changes to apply.${NC}"



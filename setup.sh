#!/bin/bash
set -e

echo "🚀 Starting Ubuntu setup..."

# -------------------------------
# 1. Update system
# -------------------------------
sudo apt update && sudo apt upgrade -y

# -------------------------------
# 2. Essentials
# -------------------------------
sudo apt install -y git curl wget python3 python3-pip build-essential apt-transport-https software-properties-common

# -------------------------------
# 3. Add Repositories (Chrome, Opera, Spotify, VS Code)
# -------------------------------

# Google Chrome
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

# Refresh repos
sudo apt update

# -------------------------------
# 4. Install Applications
# -------------------------------
sudo apt install -y \
    telegram-desktop \
    code \
    google-chrome-stable \
    opera-stable \
    spotify-client

echo "✅ Applications installed!"

# -------------------------------
# 5. Keyboard Shortcuts (Pop!_OS style)
# -------------------------------
echo "🔧 Applying keyboard shortcut tweaks..."

# Alt+Tab = switch between applications
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Alt>Tab']"

# Disable Alt+Tab window switching
gsettings set org.gnome.desktop.wm.keybindings switch-windows "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "[]"

# Alt+` = switch between windows of the same app
gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Alt>grave']"
gsettings set org.gnome.desktop.wm.keybindings switch-group-backward "['<Shift><Alt>grave']"

echo "✅ Keyboard shortcuts set!"

# -------------------------------
# 6. Restore VS Code Extensions
# -------------------------------
echo "📦 Restoring VS Code extensions..."

if [ -f vscode-extensions.txt ]; then
    xargs -n1 code --install-extension < vscode-extensions.txt
    echo "✅ VS Code extensions restored!"
else
    echo "⚠️ No vscode-extensions.txt found, skipping extensions."
fi

# -------------------------------
# Done
# -------------------------------
echo "🎉 Setup complete! Please reboot for all changes to apply."


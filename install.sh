#!/usr/bin/env bash

set -e pipefail

# Check if the script is running under Ubuntu 18.04
if [ "$(lsb_release -cs)" != "bionic" ]; then
    echo "This script is made for Ubuntu 18.04!" >&2
    exit 1
fi

# Set up global vars
GITHUB_GIST_TOKEN=null
GITHUB_GIST_ID=null

# Set the colors to use
# black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
# yellow=$(tput setaf 3)
blue=$(tput setaf 4)
# magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
# white=$(tput setaf 7)

# Reset the style
reset=$(tput sgr0)

# Color-echo
# arg $1 = color
# arg $2 = message
cecho() {
    echo "${1}${2}${reset}"
}

# Echo newline
echo_nl() {
    echo -e "\n"
}

# Install multiple packages
Install() {
    if [ "${1}" == "-q" ]; then
        params=($@)
        for pkg in "${params[@]:1}"; do
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${pkg}" > /dev/null || true
        done
    else
        for pkg in "$@"; do
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkg}" || true
        done
    fi
    sudo dpkg --configure -a || true
    sudo apt-get autoclean && sudo apt-get clean
}

#################################################
#                    Welcome                    #
#################################################

echo_nl
cecho $blue "#################################################"
cecho $blue "#                                               #"
cecho $blue "#       Ubuntu Setup Installation Script        #"
cecho $blue "#                                               #"
cecho $blue "#              by vietduc01100001               #"
cecho $blue "#                                               #"
cecho $blue "#  Note: You need to be sudo before continuing  #"
cecho $blue "#                                               #"
cecho $blue "#################################################"
echo_nl

# Ask for the administrator password and run an infinite loop
# to update existing `sudo` timestamp until script has finished
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

#################################################
#          Update package source list           #
#################################################

UpdatePkgSrcList() {
    cecho $cyan "Updating package source list..."
    sudo apt-get update -qq || true
    sudo dpkg --configure -a || true
    sudo sed -i 's/enabled=1/enabled=0/' /etc/default/apport
    cecho $green "Updated package source list"

    cecho $cyan "Installing dependency packages..."
    Install -q wget curl git gdebi apt-transport-https ca-certificates gnupg-agent software-properties-common
    cecho $green "Installed dependency packages"

    cecho $cyan "Adding APT repositories..."

    # Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    # MongoDB
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
    echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list > /dev/null

    # VSCode
    curl -s https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

    # Ibus Bamboo
    sudo add-apt-repository -y ppa:bamboo-engine/ibus-bamboo

    sudo apt-get update -qq
    cecho $green "Added APT repositories"
}

#################################################
#               Install packages                #
#################################################

InstallFzf() {
    if [ ! -d "$HOME/.fzf" ]; then
        cecho $cyan "Installing fzf..."
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all
        cecho $green "Installed fzf"
    else
        cecho $green "fzf is already installed"
    fi
}

InstallDocker() {
    if ! command -v docker > /dev/null; then
        cecho $cyan "Installing Docker..."
        Install docker-ce docker-ce-cli containerd.io
        cecho $green "Installed Docker"
    else
        cecho $green "Docker is already installed"
    fi
}

InstallDockerCompose() {
    if ! command -v docker-compose > /dev/null; then
        cecho $cyan "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || true
        sudo chmod +x /usr/local/bin/docker-compose
        cecho $green "Installed Docker Compose"
    else
        cecho $green "Docker Compose is already installed"
    fi
}

InstallNvm() {
    if ! command -v nvm > /dev/null; then
        cecho $cyan "Installing nvm"
        curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        cecho $green "Installed nvm"
    else
        cecho $green "nvm is already installed"
    fi
}

InstallNodejs() {
    if ! command -v nvm > /dev/null; then
        cecho $red "nvm is not installed"
        InstallNvm
    fi
    if ! command -v node > /dev/null; then
        cecho $cyan "Installing Node.js..."
        nvm install --lts --latest-npm
        nvm alias default node
        cecho $green "Installed Node.js"
    else
        cecho $green "Node.js is already installed"
    fi
}

InstallMongoDb() {
    if ! command -v mongo > /dev/null; then
        cecho $cyan "Installing MongoDB..."
        Install mongodb-org
        sudo systemctl enable mongod
        cecho $green "Installed MongoDB"
    else
        cecho $green "MongoDB is already installed"
    fi
}

InstallRedis() {
    if ! command -v redis-cli > /dev/null; then
        cecho $cyan "Installing Redis..."
        Install redis-server
        sudo sed -i 's/supervised no/supervised systemd/g' /etc/redis/redis.conf
        sudo systemctl enable redis
        cecho $green "Installed Redis"
    else
        cecho $green "Redis is already installed"
    fi
}

InstallVSCode() {
    if ! command -v code > /dev/null; then
        cecho $cyan "Installing VSCode..."
        Install code
        cecho $green "Installed VSCode"
    else
        cecho $green "VSCode is already installed"
    fi
}

InstallWebStorm() {
    if [ ! -d "/opt/WebStorm" ]; then
        cecho $cyan "Installing WebStorm..."
        curl https://download-cf.jetbrains.com/webstorm/WebStorm-2019.1.tar.gz -o WebStorm-2019.1.tar.gz
        sudo tar xfz WebStorm-2019.1.tar.gz -C /opt/
        sudo mv /opt/WebStorm-191.6183.63 /opt/WebStorm
        sudo sh /opt/WebStorm/bin/webstorm.sh || true
        cecho $green "Installed WebStorm"
    else
        cecho $green "WebStorm is already installed"
    fi
}

InstallChrome() {
    if ! which "google-chrome" > /dev/null; then
        cecho $cyan "Installing Google Chrome..."
        curl -s https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o google-chrome-stable_current_amd64.deb
        yes Y | sudo gdebi google-chrome-stable_current_amd64.deb
        cecho $green "Installed Google Chrome"
    else
        cecho $green "Google Chrome is already installed"
    fi
}

InstallStudio3T() {
    if [ ! -d "/opt/studio3t" ]; then
        cecho $cyan "Installing Studio 3T..."
        curl https://download.studio3t.com/studio-3t/linux/2019.2.1/studio-3t-linux-x64.tar.gz -o studio-3t-linux-x64.tar.gz
        tar xfz studio-3t-linux-x64.tar.gz
        sudo sh ./studio-3t-linux-x64.sh || true
        cecho $green "Installed Studio 3T"
    else
        cecho $green "Studio 3T is already installed"
    fi
}

InstallTelegram() {
    if [ ! -d "/opt/Telegram" ]; then
        cecho $cyan "Installing Telegram..."
        wget -O- https://telegram.org/dl/desktop/linux | sudo tar xJ -C /opt/
        cecho $green "Installed Telegram"
    else
        cecho $green "Telegram is already installed"
    fi
}

InstallIbusBamboo() {
    cecho $cyan "Installing Ibus Bamboo..."
    Install ibus-bamboo
    ibus restart
    cecho $green "Installed Ibus Bamboo"
}

#################################################
#                Set up packages                #
#################################################

SetUpDocker() {
    cecho $cyan "Setting up Docker..."
    sudo gpasswd -a "$(users)" docker
    sudo usermod -a -G docker "$(users)"
    echo '{"features":{"buildkit":true}}' | sudo tee /etc/docker/daemon.json > /dev/null
    cecho $green "Docker is set up"
}

SetUpVSCode() {
    GLOBAL_SETTINGS="$HOME/.config/Code/User/syncLocalSettings.json"
    GIST_SETTINGS="$HOME/.config/Code/User/settings.json"

    cecho $cyan "Setting up VSCode..."
    code --install-extension Shan.code-settings-sync --force
    npm install -g json > /dev/null

    # Edit global settings
    echo '{}' > $GLOBAL_SETTINGS
    json -I -f $GLOBAL_SETTINGS \
        -e 'this.ignoreUploadFiles=["projects.json","projects_cache_vscode.json","projects_cache_git.json","projects_cache_svn.json","gpm_projects.json","gpm-recentItems.json"]' \
        -e 'this.ignoreUploadFolders=["workspaceStorage"]' \
        -e 'this.ignoreExtensions=["ignored_extension_name"]' \
        -e 'this.gistDescription="Visual Studio Code Settings Sync Gist"' \
        -e 'this.version=310' \
        -e "this.token=\"${GITHUB_GIST_TOKEN}\"" \
        -e 'this.downloadPublicGist=false' \
        -e 'this.supportedFileExtensions=["json","code-snippets"]' \
        -e 'this.openTokenLink=true' \
        -e 'this.lastUpload=null' \
        -e 'this.lastDownload=null' \
        -e 'this.githubEnterpriseUrl=null' \
        -e 'this.hostname=null' \
        > /dev/null

    # Edit gist settings
    if [ ! -e $GIST_SETTINGS ]; then
        echo '{"sync":{}}' > $GIST_SETTINGS
    else
        json -I -f $GIST_SETTINGS -e 'this.sync={}' > /dev/null
    fi
    json -I -f $GIST_SETTINGS \
        -e "this.sync.gist=\"${GITHUB_GIST_ID}\"" \
        -e 'this.sync.autoDownload=false' \
        -e 'this.sync.autoUpload=true' \
        -e 'this.sync.forceDownload=false' \
        -e 'this.sync.quietSync=true' \
        -e 'this.sync.askGistName=false' \
        -e 'this.sync.removeExtensions=true' \
        -e 'this.sync.syncExtensions=true' \
        > /dev/null

    npm uninstall -g json > /dev/null
    cecho $green "VSCode is set up"
}

UninstallFirefox() {
    cecho $cyan "Uninstalling Mozilla Firefox..."
    sudo apt-get remove --purge -y firefox
    sudo rm -rf ~/.mozilla /etc/firefox /usr/lib/firefox /usr/lib/firefox-addons
    cecho $green "Uninstalled Mozilla Firefox"
}

#################################################
#         Personalize system settings           #
#################################################

FixFreezing() {
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash acpi=force"/' /etc/default/grub
    cecho $green "Fixed shutdown/restart freezing"
}

InstallDrivers() {
    cecho $cyan "Installing graphics card drivers..."
    sudo ubuntu-drivers autoinstall || true
    cecho $green "Installed graphics card drivers"
}

ChangeSettings() {
    # Blank screen
    gsettings set org.gnome.desktop.session idle-delay uint32 600 > /dev/null || true

    # Night light
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true > /dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false > /dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 18.0 > /dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 7.0 > /dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 5500 > /dev/null || true

    # Change folder view
    gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' > /dev/null || true

    # Clock format
    gsettings set org.gnome.desktop.interface clock-format '12h' > /dev/null || true

    # Trash & Temp Files
    gsettings set org.gnome.desktop.privacy remove-old-trash-files true > /dev/null || true
    gsettings set org.gnome.desktop.privacy remove-old-temp-files true > /dev/null || true
    gsettings set org.gnome.desktop.privacy old-files-age uint32 7 > /dev/null || true

    # Usage & History
    gsettings set org.gnome.desktop.privacy remember-recent-files false > /dev/null || true

    # Mouse speed
    gsettings set org.gnome.desktop.peripherals.mouse speed -0.084837545126353775 > /dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad speed -0.42779783393501802 > /dev/null || true

    # Power Button action
    gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'nothing' > /dev/null || true

    # Keyboard shortcuts
    gsettings set org.gnome.settings-daemon.plugins.media-keys home '<Super>e' > /dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys www 'HomePage' > /dev/null || true

    # Enable Ibus Bamboo
    gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'Bamboo')]" > /dev/null || true

    cecho $green "Applied personal settings"
}

InstallDotfiles() {
    cat dotfiles/bash_aliases > ~/.bash_aliases
    cat dotfiles/bash_aliases_git > ~/.bash_aliases_git
    cat dotfiles/bash_aliases_docker > ~/.bash_aliases_docker
    cat dotfiles/gitconfig > ~/.gitconfig
    cecho $green "Installed dotfiles"
}

InstallFonts() {
    ROBOTO_MONO="/usr/share/fonts/truetype/RobotoMono"
    SF_PRO="/usr/share/fonts/opentype/SFPro"

    cecho $cyan "Installing fonts..."
    if [ ! -d "$ROBOTO_MONO" ]; then sudo mkdir -p $ROBOTO_MONO; fi
    if [ ! -d "$SF_PRO" ]; then sudo mkdir -p $SF_PRO; fi
    sudo cp fonts/RobotoMono/* $ROBOTO_MONO/
    sudo cp fonts/SFPro/* $SF_PRO/
    sudo fc-cache -fv > /dev/null
    cecho $green "Installed fonts"
}

InstallChromeExtension() {
  EXT_DIR="/opt/google/chrome/extensions"
  sudo mkdir -p $EXT_DIR
  echo '{"external_URL":"https://clients2.google.com/service/update2/crx"}' | sudo tee "$EXT_DIR/${1}.json" > /dev/null
  cecho $green "Chrome extension installed: ${2}"
}

InstallMacOsTheme() {
    cecho $cyan "Installing MacOS theme..."
    echo "Light or Dark? [l/D] "
    read -r theme
    if [ -z "${theme}" ]; then
        theme="dark"
    fi
    if [[ "${theme}" =~ ^([dD][aA][rR][kK]|[dD])$ ]]; then
        theme="dark"
    else
        theme="light"
    fi

    # Copy theme files
    if [ ! -d "$HOME/.themes" ]; then mkdir ~/.themes; fi
    if [ ! -d "$HOME/.icons" ]; then mkdir ~/.icons; fi
    rm -rf ~/.themes/* ~/.icons/*
    tar xf "themes/Mojave-$theme.tar.xz" -C ~/.themes/
    tar xfz "themes/Mojave-CT-$theme.tar.gz" -C ~/.icons/
    tar xfj themes/OSX-ElCap.tar.bz2 -C ~/.icons/ OSX-ElCap/OSX-ElCap --strip-components 1
    cp "themes/mojave-$theme.jpg" ~/.themes/

    # Install theming packages
    Install gnome-tweak-tool gnome-shell-extensions chrome-gnome-shell
    InstallChromeExtension "gphhapmejobijbbhgpjhcjognlahblep" "GNOME Shell Integration"

    # Create extension directory
    EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
    if [ ! -d "$EXT_DIR" ]; then mkdir -p $EXT_DIR; fi
    rm -rf $EXT_DIR/*

    # Install Dash to Dock extension
    DASH_TO_DOCK=$(unzip -c extensions/dash-to-dock.zip metadata.json | grep uuid | cut -d \" -f4)
    mkdir -p "$EXT_DIR/$DASH_TO_DOCK"
    unzip -o -qq extensions/dash-to-dock.zip -d "$EXT_DIR/$DASH_TO_DOCK"

    # Install Move Clock extension
    MOVE_CLOCK=$(unzip -c extensions/move-clock.zip metadata.json | grep uuid | cut -d \" -f4)
    mkdir -p "$EXT_DIR/$MOVE_CLOCK"
    unzip -o -qq extensions/move-clock.zip -d "$EXT_DIR/$MOVE_CLOCK"

    # Install Clipboard extension
    CLIPBOARD=$(unzip -c extensions/clipboard-indicator.zip metadata.json | grep uuid | cut -d \" -f4)
    mkdir -p "$EXT_DIR/$CLIPBOARD"
    unzip -o -qq extensions/clipboard-indicator.zip -d "$EXT_DIR/$CLIPBOARD"

    # Enable extensions
    USER_THEMES="user-theme@gnome-shell-extensions.gcampax.github.com"
    gsettings set org.gnome.shell enabled-extensions "['$USER_THEMES', '$DASH_TO_DOCK', '$MOVE_CLOCK', '$CLIPBOARD']" > /dev/null || true

    # Change theme
    gsettings set org.gnome.desktop.interface gtk-theme "Mojave-$theme" > /dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "Mojave-CT-$theme" > /dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme 'OSX-ElCap' > /dev/null || true
    gsettings set org.gnome.shell.extensions.user-theme name "Mojave-$theme" > /dev/null || true
    gsettings set org.gnome.terminal.legacy theme-variant "$theme" > /dev/null || true

    # Change font
    gsettings set org.gnome.desktop.wm.preferences titlebar-font 'SF Pro Display 11' > /dev/null || true
    gsettings set org.gnome.desktop.interface font-name 'SF Pro Display 10' > /dev/null || true
    gsettings set org.gnome.desktop.interface document-font-name 'SF Pro Display 10' > /dev/null || true
    gsettings set org.gnome.desktop.interface monospace-font-name 'Roboto Mono 11' > /dev/null || true

    # Change wallpaper
    gsettings set org.gnome.desktop.background picture-uri "file://$HOME/.themes/mojave-$theme.jpg" > /dev/null || true
    gsettings set org.gnome.desktop.screensaver picture-uri "file://$HOME/.themes/mojave-$theme.jpg" > /dev/null || true

    # Personalize Dock
    gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'org.gnome.Software.desktop', 'org.gnome.Terminal.desktop', 'google-chrome.desktop', 'code.desktop', 'Studio 3T Linux-0.desktop', 'gnome-system-monitor_gnome-system-monitor.desktop']" > /dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM' > /dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true > /dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 40 > /dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true > /dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize' > /dev/null || true

    # Personalize Clipboard
    gsettings set org.gnome.shell.extensions.clipboard-indicator notify-on-copy false > /dev/null || true
    gsettings set org.gnome.shell.extensions.clipboard-indicator toggle-menu "['<Super>v']" > /dev/null || true

    # Change other settings
    gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:' > /dev/null || true
    gsettings set org.gnome.desktop.interface gtk-enable-primary-paste false > /dev/null || true
    gsettings set org.gnome.desktop.background show-desktop-icons false > /dev/null || true

    cecho $green "Installed MacOS theme"
}

#################################################
#                   Clean up                    #
#################################################

CleanUp() {
    # Remove temporary files
    sudo apt clean && rm -rf -- *.deb* *.gpg* && rm -f *.tar.gz

    # Install updates then remove unused packages
    sudo apt-get update -qq
    sudo apt-get upgrade -y --allow-unauthenticated
    sudo apt-get clean && sudo apt-get autoclean
    sudo apt-get autoremove --purge

    cecho $green "Reboot system now? [Y/n] "
    read -r response
    if [ -z "${response}" ]; then
        response="yes"
    fi
    if [[ "${response}" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        sudo shutdown -r now
    fi
}

#################################################
#                  Main script                  #
#################################################

main() {
    echo_nl
    cecho $blue "#################################################"
    cecho $blue "#          Update package source list           #"
    cecho $blue "#################################################"
    echo_nl

    UpdatePkgSrcList

    echo_nl
    cecho $blue "#################################################"
    cecho $blue "#               Install packages                #"
    cecho $blue "#################################################"
    echo_nl

    InstallFzf
    InstallDocker
    InstallDockerCompose
    InstallNodejs
    InstallMongoDb
    InstallRedis
    InstallVSCode
    #InstallWebStorm
    InstallChrome
    InstallStudio3T
    #InstallTelegram
    InstallIbusBamboo

    echo_nl
    cecho $blue "#################################################"
    cecho $blue "#                Set up packages                #"
    cecho $blue "#################################################"
    echo_nl

    SetUpDocker
    SetUpVSCode
    UninstallFirefox

    echo_nl
    cecho $blue "#################################################"
    cecho $blue "#         Personalize system settings           #"
    cecho $blue "#################################################"
    echo_nl

    FixFreezing
    InstallDrivers
    ChangeSettings
    InstallDotfiles
    InstallFonts
    InstallMacOsTheme

    echo_nl
    cecho $blue "#################################################"
    cecho $blue "#             Ubuntu Setup Complete             #"
    cecho $blue "#################################################"
    echo_nl

    CleanUp
}

main

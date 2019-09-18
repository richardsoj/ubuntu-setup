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
    Install -q wget curl git gdebi apt-transport-https ca-certificates gnupg-agent software-properties-common default-jre
    cecho $green "Installed dependency packages"

    cecho $cyan "Adding APT repositories..."

    # FPrint
    sudo add-apt-repository -y ppa:fingerprint/fprint

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

    # SimpleScreenRecorder
    sudo add-apt-repository -y ppa:maarten-baert/simplescreenrecorder

    # UNetbootin
    sudo add-apt-repository -y ppa:gezakovacs/ppa

    sudo apt-get update -qq
    cecho $green "Added APT repositories"
}

#################################################
#               Install packages                #
#################################################

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

InstallRedisDesktopManager() {
    if [ ! -d "/snap/redis-desktop-manager" ]; then
        cecho $cyan "Installing Redis Desktop Manager..."
        sudo snap install redis-desktop-manager
        cecho $green "Installed Redis Desktop Manager"
    else
        cecho $green "Redis Desktop Manager is already installed"
    fi
}

InstallPostman() {
    if [ ! -d "/snap/postman" ]; then
        cecho $cyan "Installing Postman..."
        sudo snap install --candidate postman
        cecho $green "Installed Postman"
    else
        cecho $green "Postman is already installed"
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

InstallSimpleScreenRecorder() {
    echo $cyan "Installing SimpleScreenRecorder..."
    Install simplescreenrecorder
    echo $green "Installed SimpleScreenRecorder"
}

InstallUNetbootin() {
    echo $cyan "Installing UNetbootin..."
    Install unetbootin
    echo $green "Installed UNetbootin"
}

#################################################
#                Set up packages                #
#################################################

SetUpGit() {
  cecho $cyan "Setting up Git..."

  gusername=''
  guseremail=''

  while [ -z "${gusername}" ]
  do
    echo "Enter username for Git commits:"
    read -r gusername
  done

  while [ -z "${guseremail}" ]
  do
    echo "Enter email for Git commits:"
    read -r guseremail
    if [[ ! "${guseremail}" =~ ^(.+@.+\..+)$ ]]; then
      guseremail=''
    fi
  done

  git config --global user.name "${gusername}"
  git config --global user.email "${guseremail}"
  git config --global push.default simple
  git config --global push.followTags true
  git config --global core.pager ""

  cecho $cyan "Generating SSH key..."
  ssh-keygen -f ~/.ssh/id_rsa -t rsa -N '' -b 4096 -C "${guseremail}" > /dev/null
  ssh-add ~/.ssh/id_rsa > /dev/null
  cecho $green "Added SSH key to ssh-agent..."

  cecho $cyan "Adding SSH key to GitHub (via api.github.com)..."
  cecho $red "This will require you to provide your GitHub username and password"

  ghusername=''

  while [ -z "${ghusername}" ]
  do
    echo "Enter GitHub username:"
    read -r ghusername
  done

  json="{"\"title"\":"\"$(users)@$(hostname)"\","\"key"\":"\"$(cat ~/.ssh/id_rsa.pub)"\"}"
  resCode=$(curl -o /dev/null -s -w "%{http_code}" -u "${ghusername}" -d "${json}" https://api.github.com/user/keys)
  echo $resCode
  if [[ "${resCode}" -eq 201 ]]; then
    cecho $green "Added SSH key to GitHub successfully"
  else
    cecho $red "SSH key is not added, please do it manually at https://github.com/settings/keys"
  fi

  cecho $green "Set up Git"
}

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
    sudo sed -i 's/GRUB_TIMEOUT=10/GRUB_TIMEOUT=3/' /etc/default/grub
    cecho $green "Fixed shutdown/restart freezing"
}

IncreaseNumberOfFileWatchers() {
    echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p || true
    cecho $green "Increased number of file watchers"
}

InstallUbuntuRestrictedExtras() {
    cecho $cyan "Installing Ubuntu restricted extras..."
    Install ubuntu-restricted-extras
    cecho $green "Installed Ubuntu restricted extras"
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
    gsettings set org.gnome.desktop.peripherals.mouse speed -0.154837545126353775 > /dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad speed -0.43779783393501802 > /dev/null || true

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
    rm -rf ~/.themes ~/.icons
    mkdir ~/.themes ~/.icons
    tar xf "themes/Mojave-$theme.tar.xz" -C ~/.themes/
    tar xf "themes/Mojave-CT-$theme.tar.xz" -C ~/.icons/
    tar xfj themes/OSX-ElCap.tar.bz2 -C ~/.icons/ OSX-ElCap/OSX-ElCap --strip-components 1
    cp "themes/mojave-$theme.jpg" "themes/mojave-$theme-blur.png" ~/.themes/
    cp "themes/gnome-shell-$theme.css" "$HOME/.themes/Mojave-$theme/gnome-shell/gnome-shell.css"
    cp themes/code.svg "$HOME/.icons/Mojave-CT-$theme/apps/128/"

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

    # Install LockKeys extension
    LOCKKEYS=$(unzip -c extensions/lockkeys.zip metadata.json | grep uuid | cut -d \" -f4)
    mkdir -p "$EXT_DIR/$LOCKKEYS"
    unzip -o -qq extensions/lockkeys.zip -d "$EXT_DIR/$LOCKKEYS"

    # Enable extensions
    USER_THEMES="user-theme@gnome-shell-extensions.gcampax.github.com"
    gsettings set org.gnome.shell enabled-extensions "['$USER_THEMES', '$DASH_TO_DOCK', '$MOVE_CLOCK', '$CLIPBOARD', '$LOCKKEYS']" > /dev/null || true

    # Change login background
    sudo sed -i "2310s|resource:///org/gnome/shell/theme/noise-texture.png|file:///home/vietduc/.themes/mojave-$theme-blur.png|" /usr/share/gnome-shell/theme/ubuntu.css
    sudo sed -i '2312i background-size: cover;\nbackground-position: center;' /usr/share/gnome-shell/theme/ubuntu.css

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
    gsettings set org.gnome.desktop.screensaver picture-uri "file://$HOME/.themes/mojave-$theme-blur.png" > /dev/null || true

    # Personalize Dock
    gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'google-chrome.desktop', 'code.desktop', 'navicat.desktop', 'Studio 3T Linux-0.desktop', 'redis-desktop-manager_rdm.desktop', 'postman_postman.desktop', 'telegramdesktop.desktop', 'chrome-piliedkdooamolekjnpahpcgkjlfbnin-Default.desktop', 'com.teamviewer.TeamViewer.desktop', 'simplescreenrecorder.desktop', 'gnome-system-monitor_gnome-system-monitor.desktop']" > /dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true > /dev/null || true
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

InstallExpect() {
    if ! command -v expect > /dev/null; then
        cecho $cyan "Installing expect..."
        Install expect
        cecho $green "Installed expect"
    else
        cecho $green "expect is already installed"
    fi
}

InstallFPrint() {
    if ! command -v fprintd-enroll > /dev/null; then
        cecho $cyan "Installing FPrint..."
        Install libfprint0 fprint-demo libpam-fprintd
        cecho $green "Installed FPrint"
    else
        cecho $green "FPrint is installed"
    fi
}

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

InstallZsh() {
    if ! command -v zsh > /dev/null; then
        cecho $cyan "Installing Zsh..."
        Install zsh powerline fonts-powerline

        cecho $cyan "Installing Oh My Zsh"
        git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
        cp dotfiles/zshrc ~/.zshrc
        sed -i "s/##WHOAMI##/$USER/g" ~/.zshrc
        source ~/.zshrc

        git clone https://github.com/denysdovhan/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt"
        ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

        source ~/.zshrc
        chsh -s $(which zsh)
        cecho $green "Installed Zsh"
    else
        cecho $green "Zsh is installed"
    fi
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
    yes Y | sudo apt-get autoremove --purge

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

    InstallDocker
    InstallDockerCompose
    InstallNodejs
    # InstallMongoDb
    InstallRedis
    InstallVSCode
    # InstallWebStorm
    InstallChrome
    InstallStudio3T
    InstallRedisDesktopManager
    InstallPostman
    InstallTelegram
    InstallIbusBamboo
    InstallSimpleScreenRecorder
    InstallUNetbootin

    echo_nl
    cecho $blue "#################################################"
    cecho $blue "#                Set up packages                #"
    cecho $blue "#################################################"
    echo_nl

    SetUpGit
    SetUpDocker
    SetUpVSCode
    UninstallFirefox

    echo_nl
    cecho $blue "#################################################"
    cecho $blue "#         Personalize system settings           #"
    cecho $blue "#################################################"
    echo_nl

    FixFreezing
    IncreaseNumberOfFileWatchers
    InstallUbuntuRestrictedExtras
    InstallDrivers
    ChangeSettings
    # InstallDotfiles
    InstallFonts
    InstallMacOsTheme
    InstallFPrint
    InstallExpect
    # InstallFzf
    InstallZsh

    echo_nl
    cecho $blue "#################################################"
    cecho $blue "#             Ubuntu Setup Complete             #"
    cecho $blue "#################################################"
    echo_nl

    CleanUp
}

main

#!/usr/bin/env bash

# Clear the screen
clear

# Turn off cursor.
setterm -cursor off

# Get fastest mirrors.
echo -n -e "Syncing with fastest mirrors. \033[0K\r"
pkg update -y 2>/dev/null

# Upgrade packages.
echo -n -e "Upgrading packages. \033[0K\r"
apt-get upgrade -o Dpkg::Options::='--force-confnew' -y 2>/dev/null

# Updating package repositories and installing packages.
echo -n -e "Installing required packages. \033[0K\r"
apt update 2>/dev/null
apt install -y curl git wget shc aria2 gh 2>/dev/null
sleep 2

# Giving Storage permision to Termux App.
if [ ! -d $HOME/storage ]; then
    echo -n -e "Setting up storage access for Termux. \033[0K\r"
    termux-setup-storage
    sleep 2
fi

# Backing up your setup
mkdir -p $HOME/storage/shared/setup
for i in "$HOME/.termux/font.ttf" "$HOME/.termux/colors.properties" "$HOME/.termux/termux.properties"
do
    if [ -f $i ]; then
        echo -n -e "Backing up current $i file. \033[0K\r"
        mv -f $i $HOME/storage/shared/setup/$(date +%Y_%m_%d_%H_%M)/$(basename $i)
        sleep 1
    fi
done
sleep 2

# Upgrade packages.
echo -n -e "Updating system packages. \033[0K\r"
pkg upgrade -y 2>/dev/null
sleep 2

# Installing the Ubuntu font for Termux.
if [ ! -f $HOME/.termux/font.ttf ]; then
    echo -n -e "Installing Ubuntu font. \033[0K\r"
    curl -fsSL -o $HOME/.termux/font.ttf 'https://raw.githubusercontent.com/akirasupr/akirasupr/setup/font.ttf'
    sleep 2
fi

# Set a default color scheme.
echo -n -e "Setting up a new color scheme. \033[0K\r"
curl -fsSL -o $HOME/.termux/colors.properties 'https://raw.githubusercontent.com/akirasupr/akirasupr/setup/colors.prop'
sleep 2

# Add new buttons to the Termux bottom bar.
echo -n -e "Setting up some extra keys in Termux. \033[0K\r"
curl -fsSL -o $HOME/.termux/termux.properties 'https://raw.githubusercontent.com/akirasupr/akirasupr/setup/termux.prop'
sleep 2

# Setup git credentials
echo -n -e "Setting up Git Credentials in Termux. \033[0K\r"
if [ ! -f $HOME/.gitconfig ]; then
    touch $HOME/.gitconfig && clear
    if [ ! $(grep "name" $HOME/.gitconfig) ]; then
        echo -n "Please enter your user name: "
        read -r name
        git config --global user.name "${name}"
    fi
    if [ ! $(grep "email" $HOME/.gitconfig) ]; then
        echo -n "Please enter your email id: "
        read -r email
        git config --global user.email "${email}"
    fi
    if [ ! $(grep "editor" $HOME/.gitconfig) ]; then
        echo -n "Please enter your core editor name: "
        read -r editor
        git config --global core.editor "${editor}"
    fi
    clear
fi
echo -n -e "Successfully updated Git Credentials \033[0K\r"
sleep 2

# Setup Gh
echo -n -e "Setting up Gh in Termux. \033[0K\r"
if [ ! -f $HOME/.config/gh ]; then
    gh auth login
    clear
fi
echo -n -e "Successfully updated Gh \033[0K\r"
sleep 1

# Reload Termux settings.
termux-reload-settings

# Setup complete.
echo -n -e "Installation complete! \033[0K\r"
sleep 1

# Restore cursor.
setterm -cursor on

# Clear the screen
clear

# Setup finished
exit

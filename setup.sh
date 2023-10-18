#!/usr/bin/env bash
username="oiakera"
email="vishal.rockstar7011@gmail.com"
editor="nano"
dir="*"

# Clear the screen
clear

# Turn off cursor.
setterm -cursor off

# Get fastest mirrors.
echo -n -e "Syncing with fastest mirrors."
pkg update -y

# Upgrade packages.
echo -n -e "Upgrading packages."
pkg upgrade -o Dpkg::Options::='--force-confnew' -y 2>/dev/null

# Updating package repositories and installing packages.
echo -n -e "Installing required packages."
pkg install git gh -y

# Giving Storage permision to Termux App.
if [ ! -d $HOME/storage ]; then
    echo -n -e "Setting up storage access for Termux."
    termux-setup-storage
fi

# Installing the Ubuntu font for Termux.
if [ ! -f $HOME/.termux/font.ttf ]; then
    echo -n -e "Installing Ubuntu font."
    curl -fsSL -o $HOME/.termux/font.ttf 'https://raw.githubusercontent.com/akirasup3r/akirasup3r/master/font.ttf'
fi

# Set a default color scheme.
echo -n -e "Setting up a new color scheme."
curl -fsSL -o $HOME/.termux/colors.properties 'https://raw.githubusercontent.com/akirasup3r/akirasup3r/master/colors.prop'

# Add new buttons to the Termux bottom bar.
echo -n -e "Setting up some extra keys in Termux."
curl -fsSL -o $HOME/.termux/termux.properties 'https://raw.githubusercontent.com/akirasup3r/akirasup3r/master/termux.prop'

# Setup git credentials
echo -n -e "Setting up Git Credentials in Termux."
if [ ! -f $HOME/.gitconfig ]; then
     git config --global user.name "${username}"
     git config --global user.email "${email}"
     git config --global core.editor "${editor}"
     if [ "$(id -u)" -ne 0 ]; then
          git config --global --add safe.directory "${dir}"
    fi
    if [ ! -f $HOME/.config/gh ]; then
        gh auth login
    fi
fi
echo -n -e "Successfully updated Git Credentials"

# Reload Termux settings.
termux-reload-settings

# Setup complete.
echo -n -e "Installation complete!"

# Restore cursor.
setterm -cursor on

# Clear the screen
clear

# Setup finished
exit

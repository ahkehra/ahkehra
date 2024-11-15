#!/usr/bin/env bash

# --- User Settings ---
username="ahkehra"
email="vishal.rockstar7011@gmail.com"
default_directory="*"
font_url="https://raw.githubusercontent.com/ahkehra/ahkehra/master/font.ttf"
color_scheme_url="https://raw.githubusercontent.com/ahkehra/ahkehra/master/colors.prop"
termux_properties_url="https://raw.githubusercontent.com/ahkehra/ahkehra/master/termux.prop"
target_folder="$HOME/storage/downloads/Termux"

# --- Helper Functions ---
output_message() { echo -e "\033[1;31m$1\033[0m"; }  # Print message in red color
disable_cursor() { setterm -cursor off; }
enable_cursor_and_clear() { setterm -cursor on; clear; }

# --- Retry Function for Curl ---
download_with_retry() {
    local url=$1
    local output=$2
    local max_attempts=5
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        output_message "Attempt $attempt to download from $url..."
        curl -fsSL --limit-rate 1M -o "$output" "$url" && break
        echo "Download failed, retrying..."
        ((attempt++))
        sleep 2
    done
}

# --- Start Setup ---
output_message "Setting up Termux..."; clear; disable_cursor

# --- Package and System Updates ---
output_message "Syncing with fastest mirrors..."; pkg update -y &>/dev/null
output_message "Upgrading installed packages..."; pkg upgrade -o Dpkg::Options::='--force-confnew' -y &>/dev/null
output_message "Installing required packages (git, gh)..."; pkg install git gh -y &>/dev/null

# --- Storage and Font Setup ---
if [ ! -d "$HOME/storage" ]; then
    output_message "Setting up Termux storage access..."; termux-setup-storage
fi

if [ ! -f "$HOME/.termux/font.ttf" ]; then
    output_message "Downloading and installing custom font..."
    download_with_retry "$font_url" "$HOME/.termux/font.ttf"
fi

# --- Apply Color Scheme and Termux Properties ---
output_message "Applying color scheme..."; curl -fsSL --limit-rate 1M -o "$HOME/.termux/colors.properties" "$color_scheme_url"
output_message "Configuring Termux extra keys..."; curl -fsSL --limit-rate 1M -o "$HOME/.termux/termux.properties" "$termux_properties_url"

# --- Git Configuration and Authentication ---
if [ ! -f "$HOME/.gitconfig" ]; then
    output_message "Setting up Git configuration..."; 
    git config --global user.name "$username"
    git config --global user.email "$email"
    git config --global core.editor "nano"
    
    if [ "$(id -u)" -ne 0 ]; then
        git config --global --add safe.directory "$default_directory"
    fi
    
    # GitHub Authentication using Personal Access Token (PAT)
    if [ ! -f "$HOME/.config/gh" ]; then
        output_message "Authenticating with GitHub using Personal Access Token (PAT)..."
        echo -e "$github_token" | gh auth login --with-token
    fi
fi

# --- Folder Check, Creation & Navigation ---
folder_created=false  # Flag to track if the folder was created

if [ ! -d "$target_folder" ]; then
    output_message "Folder $target_folder does not exist."
    output_message "Do you want to create it? (y/n):"
    read create_folder_choice
    if [[ "$create_folder_choice" == "y" || "$create_folder_choice" == "Y" ]]; then
        output_message "Creating folder $target_folder..."
        mkdir -p "$target_folder"
        output_message "Folder $target_folder created."
        folder_created=true  # Set flag to true if folder is created
    else
        output_message "Skipping folder creation."
    fi
fi

# --- Add Folder Navigation to .bashrc if Folder is Created ---
if [ "$folder_created" = true ]; then
    output_message "Adding folder navigation to .bashrc..."

    # Check if the line already exists, if not, append it
    if ! grep -q "cd $target_folder" ~/.bashrc; then
        echo "cd $target_folder" >> ~/.bashrc
        output_message "Successfully added folder navigation to .bashrc."
    else
        output_message "Folder navigation already exists in .bashrc."
    fi
fi

# --- Finish Setup ---
output_message "Setup completed successfully!"; enable_cursor_and_clear; exit 0

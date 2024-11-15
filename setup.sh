#!/usr/bin/env bash

# --- User Settings ---
output_message() { echo -e "\033[1;31m$1\033[0m"; }  # Print message in red color
disable_cursor() { setterm -cursor off; }
enable_cursor_and_clear() { setterm -cursor on; clear; }

# --- Prompt for Username and Email (Required) ---
output_message "Please enter your GitHub username: "
read username
while [[ -z "$username" ]]; do
    output_message "Username is required! Please enter your GitHub username: "
    read username
done
output_message "Username entered: $username"

output_message "Please enter your email address for GitHub: "
read email
while [[ -z "$email" ]]; do
    output_message "Email is required! Please enter your email address for GitHub: "
    read email
done
output_message "Email entered: $email"

# --- Dynamic URL Assignment Based on Username ---
font_url="https://raw.githubusercontent.com/$username/ahkehra/master/font.ttf"
color_scheme_url="https://raw.githubusercontent.com/$username/ahkehra/master/colors.prop"
termux_properties_url="https://raw.githubusercontent.com/$username/ahkehra/master/termux.prop"
target_folder="$HOME/storage/downloads/Termux"

# --- Check Required Commands ---
command -v curl >/dev/null 2>&1 || { output_message "curl is required but not installed. Exiting..."; exit 1; }
command -v git >/dev/null 2>&1 || { output_message "git is required but not installed. Exiting..."; exit 1; }
command -v gh >/dev/null 2>&1 || { output_message "GitHub CLI (gh) is required but not installed. Exiting..."; exit 1; }

# --- Start Setup ---
output_message "Setting up Termux..."; clear; disable_cursor

# --- Package and System Updates ---
output_message "Syncing with fastest mirrors..."; pkg update -y &>/dev/null
output_message "Upgrading installed packages..."; pkg upgrade -o Dpkg::Options::='--force-confnew' -y &>/dev/null
output_message "Installing required packages (git, gh)..."; pkg install git gh -y &>/dev/null

# --- Ask for Zsh Installation ---
output_message "Do you want to install Zsh (y/n)?"
read install_zsh
if [[ "$install_zsh" == "y" || "$install_zsh" == "Y" ]]; then
    output_message "Installing Zsh..."
    pkg install zsh -y &>/dev/null
    output_message "Zsh installed successfully."
    output_message "Changing default shell to Zsh..."
    chsh -s $(which zsh)
    output_message "Default shell changed to Zsh. Please restart Termux for changes to take effect."
else
    output_message "Skipping Zsh installation."
fi

# --- Storage and Font Setup ---
if [ ! -d "$HOME/storage" ]; then
    output_message "Setting up Termux storage access..."; termux-setup-storage
fi

# --- Ensure ~/.termux Directory Exists ---
if [ ! -d "$HOME/.termux" ]; then
    output_message "Creating ~/.termux directory for font and theme configuration..."
    mkdir -p "$HOME/.termux"
fi

# --- Install Font if Not Present ---
if [ ! -f "$HOME/.termux/font.ttf" ]; then
    output_message "Downloading and installing custom font..."; curl -fsSL -o "$HOME/.termux/font.ttf" "$font_url"
fi

# --- Apply Color Scheme and Termux Properties ---
output_message "Applying color scheme..."; curl -fsSL -o "$HOME/.termux/colors.properties" "$color_scheme_url"
output_message "Configuring Termux extra keys..."; curl -fsSL -o "$HOME/.termux/termux.properties" "$termux_properties_url"

# --- Git Configuration and Authentication ---
if [ ! -f "$HOME/.gitconfig" ]; then
    output_message "Setting up Git configuration..."; 
    git config --global user.name "$username"
    git config --global user.email "$email"
    git config --global core.editor "nano"
    
    if [ "$(id -u)" -ne 0 ]; then
        git config --global --add safe.directory "$HOME"
    fi
    
    # Check if the user is already authenticated
    if ! gh auth status &>/dev/null; then
        output_message "You are not logged in to GitHub. Starting GitHub authentication..."

        # Start the GitHub authentication process with the web flow
        output_message "Run 'gh auth login' in the terminal and follow the prompts to authenticate using your browser."
        
        # Give the user instructions
        output_message "The following steps will guide you through the authentication process:"
        output_message "1. Choose 'Login with a web browser' when prompted."
        output_message "2. Visit the URL provided in your browser (e.g., https://github.com/login/device)."
        output_message "3. Enter the code displayed in your terminal after visiting the URL."
        output_message "4. After successful login, return to the terminal."
        
        output_message "Once you're logged in, the script will continue. Press Enter to proceed after completing the login."
        read -p "Press Enter to continue after authentication..."

        # Try to login with the web flow and ensure it's successful
        gh auth login
    fi
fi

# --- Folder Check, Creation & Navigation ---
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
        folder_created=false
    fi
fi

# --- Add Folder Navigation to .bashrc or .zshrc if Folder is Created ---
if [ "$folder_created" = true ]; then
    output_message "Adding folder navigation to the appropriate config file..."

    # Check if the user is using bash or zsh
    if [ -n "$ZSH_VERSION" ]; then
        shell_config="$HOME/.zshrc"
    else
        shell_config="$HOME/.bashrc"
    fi
    
    # Check if the line already exists in the config file, if not, append it
    if ! grep -q "cd $target_folder" "$shell_config"; then
        echo "cd $target_folder" >> "$shell_config"
        output_message "Successfully added folder navigation to $shell_config."
    else
        output_message "Folder navigation already exists in $shell_config."
    fi
fi

# --- Finish Setup ---
output_message "Setup completed successfully!"; enable_cursor_and_clear; exit 0

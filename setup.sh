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

# --- Package List (Permanent and Optional) ---
packages=("curl" "git" "gh" "zsh")  # Required permanent packages

# --- Unified Package Installation, System Update, and Optional Package Addition ---
setup_system() {
    # Ask if the user wants to update the system
    output_message "Do you want to update the system and sync the package repositories? (y/n)"
    read update_choice
    if [[ "$update_choice" == "y" || "$update_choice" == "Y" ]]; then
        output_message "Syncing with fastest mirrors..."; pkg update -y &>/dev/null
        output_message "Upgrading installed packages..."; pkg upgrade -o Dpkg::Options::='--force-confnew' -y &>/dev/null
    else
        output_message "Skipping system update and upgrade."
    fi

    # Install required permanent packages
    output_message "Installing required packages..."
    for package in "${packages[@]}"; do
        command -v "$package" >/dev/null 2>&1 || {
            output_message "$package is not installed. Installing..."
            if pkg install "$package" -y &>/dev/null; then
                output_message "$package installed successfully."
            else
                output_message "Failed to install $package. Please try again."
                exit 1
            fi
        }
    done

    # Ask for additional packages from the user
    output_message "Do you want to install additional packages? (y/n)"
    read install_new_packages
    if [[ "$install_new_packages" == "y" || "$install_new_packages" == "Y" ]]; then
        output_message "Enter the package names you want to install (separated by spaces):"
        read -a optional_packages
        for package in "${optional_packages[@]}"; do
            output_message "Installing $package..."
            if pkg install "$package" -y &>/dev/null; then
                output_message "$package installed successfully."
            else
                output_message "Failed to install $package."
            fi
        done
    else
        output_message "Skipping additional package installation."
    fi
}

# --- Install Zsh Option ---
install_zsh() {
    output_message "Do you want to install Zsh (y/n)?"
    read install_zsh
    if [[ "$install_zsh" == "y" || "$install_zsh" == "Y" ]]; then
        output_message "Installing Zsh..."
        if pkg install zsh -y &>/dev/null; then
            output_message "Zsh installed successfully."
            output_message "Changing default shell to Zsh..."
            chsh -s $(which zsh)
            output_message "Default shell changed to Zsh. Please restart Termux for changes to take effect."
        else
            output_message "Failed to install Zsh."
        fi
    else
        output_message "Skipping Zsh installation."
    fi
}

# --- Start Setup ---
output_message "Setting up Termux..."; clear; disable_cursor

# --- Run System Setup, Updates, and Package Installation ---
setup_system  # Update system, install required packages, and optional packages

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

        if gh auth status &>/dev/null; then
            output_message "GitHub authentication successful."
        else
            output_message "GitHub authentication failed. Please try again."
            exit 1
        fi
    else
        output_message "Already logged in to GitHub."
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
output_message "Setup completed successfully!"; enable_cursor_and_clear

# --- Restart Termux Automatically ---
output_message "Restarting Termux to apply all changes..."
killall com.termux
sleep 2
am start --user 0 -n com.termux/.HomeActivity
exit 0

#!/usr/bin/env bash

# --- Output helper ---
output_message() { echo -e "\033[1;32m$1\033[0m"; }  # Green
error_message() { echo -e "\033[1;31m$1\033[0m"; }  # Red
disable_cursor() { setterm -cursor off; }
enable_cursor_and_clear() { setterm -cursor on; clear; }

# --- Defaults for auto mode ---
AUTO_MODE=false
AUTO_USERNAME="${GIT_USERNAME:-myuser}"
AUTO_EMAIL="${GIT_EMAIL:-myuser@example.com}"
AUTO_EXTRA="${GIT_EXTRA:-}"
AUTO_INSTALL_ZSH="${INSTALL_ZSH:-true}"
TARGET_FOLDER="$HOME/storage/downloads/Termux"

# --- Parse arguments ---
for arg in "$@"; do
    case $arg in
        --auto) AUTO_MODE=true ;;
    esac
done

# --- Prompt for Username ---
get_username() {
    if $AUTO_MODE; then
        username="$AUTO_USERNAME"
        git config --global user.name "$username"
        output_message "✅ Username set (auto): $username"
    else
        while true; do
            output_message "Enter your GitHub username:"
            read username
            if [ -n "$username" ]; then
                git config --global user.name "$username"
                output_message "✅ Username set: $username"
                break
            else
                error_message "Username cannot be empty. Please try again."
            fi
        done
    fi
}

# --- Prompt for Email ---
get_email() {
    if $AUTO_MODE; then
        email="$AUTO_EMAIL"
        git config --global user.email "$email"
        output_message "✅ Email set (auto): $email"
    else
        while true; do
            output_message "Enter your GitHub email:"
            read email
            if [ -n "$email" ]; then
                git config --global user.email "$email"
                output_message "✅ Email set: $email"
                break
            else
                error_message "Email cannot be empty. Please try again."
            fi
        done
    fi
}

# --- Git Extras (optional) ---
get_extras() {
    if $AUTO_MODE; then
        if [ -n "$AUTO_EXTRA" ]; then
            eval git config --global $AUTO_EXTRA
            output_message "Extras applied (auto): $AUTO_EXTRA"
        fi
    else
        output_message "Enter any extra Git config (or press Enter to skip):"
        read extras
        if [ -n "$extras" ]; then
            eval git config --global $extras
            output_message "Extras applied: $extras"
        else
            output_message "No extras added."
        fi
    fi
}

# --- System Setup ---
setup_system() {
    packages=("curl" "git" "gh")

    if $AUTO_MODE; then
        output_message "🔄 Updating system (auto)..."
        pkg update -y &>/dev/null
        pkg upgrade -o Dpkg::Options::='--force-confnew' -y &>/dev/null
    else
        output_message "Do you want to update the system and sync repositories? (y/n)"
        read update_choice
        if [[ "$update_choice" =~ ^[Yy]$ ]]; then
            pkg update -y &>/dev/null
            pkg upgrade -o Dpkg::Options::='--force-confnew' -y &>/dev/null
        fi
    fi

    output_message "Installing required packages..."
    for package in "${packages[@]}"; do
        if ! command -v "$package" >/dev/null 2>&1; then
            pkg install "$package" -y &>/dev/null || {
                error_message "Failed to install $package"
                exit 1
            }
        fi
    done

    if ! $AUTO_MODE; then
        output_message "Do you want to install extra packages? (y/n)"
        read extra_choice
        if [[ "$extra_choice" =~ ^[Yy]$ ]]; then
            output_message "Enter packages separated by spaces:"
            read -a optional_packages
            for package in "${optional_packages[@]}"; do
                pkg install "$package" -y &>/dev/null || error_message "Failed to install $package"
            done
        fi
    fi
}

# --- Zsh Install ---
get_zsh_choice() {
    if $AUTO_MODE; then
        if [ "$AUTO_INSTALL_ZSH" = "true" ]; then
            pkg install zsh -y &>/dev/null
            chsh -s "$(which zsh)"
            output_message "✅ Zsh installed and set as default shell (auto)."
        else
            output_message "Skipping Zsh install (auto)."
        fi
    else
        while true; do
            output_message "Do you want to set Zsh as default shell? (y/n):"
            read zsh_choice
            case "$zsh_choice" in
                y|Y)
                    pkg install zsh -y &>/dev/null
                    chsh -s "$(which zsh)"
                    output_message "✅ Zsh installed and set as default shell."
                    break ;;
                n|N)
                    output_message "Skipping Zsh installation."
                    break ;;
                *) error_message "Invalid choice. Please enter y or n." ;;
            esac
        done
    fi
}

# --- GitHub Login ---
github_login() {
    if gh auth status &>/dev/null; then
        output_message "✅ Already logged in to GitHub."
    else
        if $AUTO_MODE; then
            output_message "Skipping GitHub login in auto mode. Run 'gh auth login' manually if needed."
        else
            gh auth login --web --git-protocol https --hostname github.com
        fi
    fi
}

# --- Root Check ---
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        output_message "⚡ Root detected. Full folder access available."
    else
        output_message "ℹ️ No root detected. Using Termux shared storage."
    fi
}

# --- Fonts and Theme ---
setup_fonts_themes() {
    font_url="https://raw.githubusercontent.com/$username/ahkehra/master/font.ttf"
    color_scheme_url="https://raw.githubusercontent.com/$username/ahkehra/master/colors.prop"
    termux_properties_url="https://raw.githubusercontent.com/$username/ahkehra/master/termux.prop"

    if [ ! -d "$HOME/storage" ]; then
        termux-setup-storage
    fi

    mkdir -p "$HOME/.termux"
    curl -fsSL -o "$HOME/.termux/font.ttf" "$font_url"
    curl -fsSL -o "$HOME/.termux/colors.properties" "$color_scheme_url"
    curl -fsSL -o "$HOME/.termux/termux.properties" "$termux_properties_url"
}

# --- Folder Setup ---
setup_folder() {
    if [ ! -d "$TARGET_FOLDER" ]; then
        if $AUTO_MODE; then
            mkdir -p "$TARGET_FOLDER"
            output_message "✅ Folder created (auto): $TARGET_FOLDER"
        else
            output_message "Folder $TARGET_FOLDER does not exist. Create it? (y/n)"
            read create_folder_choice
            if [[ "$create_folder_choice" =~ ^[Yy]$ ]]; then
                mkdir -p "$TARGET_FOLDER"
                output_message "✅ Folder created: $TARGET_FOLDER"
            fi
        fi
    fi

    if [ -n "$ZSH_VERSION" ]; then
        shell_config="$HOME/.zshrc"
    else
        shell_config="$HOME/.bashrc"
    fi

    if ! grep -q "cd $TARGET_FOLDER" "$shell_config"; then
        echo "cd $TARGET_FOLDER" >> "$shell_config"
        output_message "✅ Auto-navigation added to $shell_config."
    fi
}

# --- Main Execution ---
clear; disable_cursor
output_message "🚀 Starting Termux setup..."

get_username
get_email

git config --global core.editor "nano"
git config --global --add safe.directory "$HOME"

get_extras
setup_system
get_zsh_choice
github_login
check_root
setup_fonts_themes
setup_folder

enable_cursor_and_clear
output_message "✅ Setup completed successfully! Please restart Termux."
exit 0

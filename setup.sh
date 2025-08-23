#!/usr/bin/env bash

# --- Output helper ---
output_message() { echo -e "\033[1;32m$1\033[0m"; }
error_message() { echo -e "\033[1;31m$1\033[0m"; }
disable_cursor() { setterm -cursor off; }
enable_cursor_and_clear() { setterm -cursor on; clear; }

# --- Defaults for auto mode ---
AUTO_MODE=false
AUTO_USERNAME="${GIT_USERNAME:-}"
AUTO_EMAIL="${GIT_EMAIL:-}"
AUTO_EXTRA="${GIT_EXTRA:-}"
AUTO_INSTALL_ZSH="${INSTALL_ZSH:-false}"
CUSTOM_PACKAGES="${CUSTOM_PACKAGES:-}"
TARGET_FOLDER="$HOME/storage/downloads/Termux"

# --- Parse args ---
for arg in "$@"; do
    case $arg in
        --auto) AUTO_MODE=true ;;
    esac
done

# --- System Setup ---
setup_system() {
    packages=("curl" "git" "gh")

    if $AUTO_MODE; then
        pkg update -y &>/dev/null
        pkg upgrade -o Dpkg::Options::='--force-confnew' -y &>/dev/null
    else
        output_message "Do you want to update system? (y/n)"
        read -s update_choice
        echo
        if [[ "$update_choice" =~ ^[Yy]$ ]]; then
            pkg update -y &>/dev/null
            pkg upgrade -o Dpkg::Options::='--force-confnew' -y &>/dev/null
        fi
    fi

    for package in "${packages[@]}"; do
        if ! command -v "$package" >/dev/null 2>&1; then
            pkg install "$package" -y &>/dev/null || {
                error_message "Failed to install $package"
                exit 1
            }
        fi
    done

    # --- Custom packages ---
    if $AUTO_MODE; then
        if [ -n "$CUSTOM_PACKAGES" ]; then
            output_message "Installing custom packages: $CUSTOM_PACKAGES"
            pkg install -y $CUSTOM_PACKAGES &>/dev/null
        fi
    else
        output_message "Enter any extra packages to install (space separated, leave blank to skip):"
        read custom_input
        if [ -n "$custom_input" ]; then
            output_message "Installing custom packages: $custom_input"
            pkg install -y $custom_input &>/dev/null
        fi
    fi
}

# --- Git username & email ---
get_git_identity() {
    if $AUTO_MODE; then
        git config --global user.name "$AUTO_USERNAME"
        git config --global user.email "$AUTO_EMAIL"
        username="$AUTO_USERNAME"
        email="$AUTO_EMAIL"
    else
        while true; do
            output_message "Enter your GitHub username:"
            read -s username
            echo
            [ -n "$username" ] && break
            error_message "Username cannot be empty."
        done
        git config --global user.name "$username"

        while true; do
            output_message "Enter your GitHub email:"
            read -s email
            echo
            [ -n "$email" ] && break
            error_message "Email cannot be empty."
        done
        git config --global user.email "$email"
    fi

    git config --global core.editor "nano"
    git config --global --add safe.directory "$HOME"

    # --- Show saved identity clearly ---
    output_message "✅ Git identity configured:"
    echo "   Username: $username"
    echo "   Email: $email"
}

# --- Git Extras ---
get_extras() {
    if $AUTO_MODE; then
        [ -n "$AUTO_EXTRA" ] && eval git config --global $AUTO_EXTRA
    else
        output_message "Enter any extra Git config (or press Enter to skip):"
        read extras
        [ -n "$extras" ] && eval git config --global $extras
    fi
}

# --- Zsh ---
get_zsh_choice() {
    if $AUTO_MODE; then
        if [ "$AUTO_INSTALL_ZSH" = "true" ]; then
            pkg install zsh -y &>/dev/null
            chsh -s "$(which zsh)"
        fi
    else
        output_message "Do you want to set Zsh as default shell? (y/n):"
        read -s zsh_choice
        echo
        case "$zsh_choice" in
            y|Y) pkg install zsh -y &>/dev/null; chsh -s "$(which zsh)" ;;
            n|N) ;;
        esac
    fi
}

# --- GitHub login ---
github_login() {
    if ! gh auth status &>/dev/null; then
        if $AUTO_MODE; then
            output_message "Skipping GitHub login in auto mode. Run 'gh auth login' manually."
        else
            gh auth login --web --git-protocol https --hostname github.com
        fi
    fi
}

# --- Root check ---
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        output_message "⚡ Root detected."
    else
        output_message "ℹ️ Running without root."
    fi
}

# --- Fonts + theme ---
setup_fonts_themes() {
    font_url="https://raw.githubusercontent.com/$username/ahkehra/master/font.ttf"
    color_scheme_url="https://raw.githubusercontent.com/$username/ahkehra/master/colors.prop"
    termux_properties_url="https://raw.githubusercontent.com/$username/ahkehra/master/termux.prop"

    [ ! -d "$HOME/storage" ] && termux-setup-storage
    mkdir -p "$HOME/.termux"
    curl -fsSL -o "$HOME/.termux/font.ttf" "$font_url"
    curl -fsSL -o "$HOME/.termux/colors.properties" "$color_scheme_url"
    curl -fsSL -o "$HOME/.termux/termux.properties" "$termux_properties_url"
}

# --- Folder setup ---
setup_folder() {
    if [ ! -d "$TARGET_FOLDER" ]; then
        if $AUTO_MODE; then
            mkdir -p "$TARGET_FOLDER"
        else
            output_message "Folder $TARGET_FOLDER does not exist. Create it? (y/n)"
            read -s choice
            echo
            [[ "$choice" =~ ^[Yy]$ ]] && mkdir -p "$TARGET_FOLDER"
        fi
    fi

    if [ -n "$ZSH_VERSION" ]; then
        shell_config="$HOME/.zshrc"
    else
        shell_config="$HOME/.bashrc"
    fi

    if ! grep -q "cd $TARGET_FOLDER" "$shell_config"; then
        echo "cd $TARGET_FOLDER" >> "$shell_config"
    fi
}

# --- Main ---
clear; disable_cursor
output_message "🚀 Starting Termux setup..."

setup_system
get_git_identity
get_extras
get_zsh_choice
github_login
check_root
setup_fonts_themes
setup_folder

enable_cursor_and_clear
output_message "✅ Setup completed successfully! Restart Termux."
exit 0

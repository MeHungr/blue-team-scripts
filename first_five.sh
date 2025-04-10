#!/bin/bash

#   ./first_five.sh -l            # Run in headless mode (no prompts, automated)
# If run in headless mode, expects config.env file in the same directory with:
# headless_pass="your_password_here"

personal_user="sockpuppet"
backup_user="puppetmaster"
script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
log_file=./blue_init.log
exec > >(tee -a "$log_file") 2>&1

if [ -f "$script_dir/config.env" ]; then
    source "$script_dir/config.env"
else
    echo "No config.env file found in $script_dir"
fi

trap 'rm -f "$script_dir/config.env"' EXIT

# ===== Detect Distro =====
if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro="${ID,,}"
else
    distro="unknown"
fi

# ===== Update System =====
update_system() {
    echo "[*] Updating system"
    case "$distro" in
        ubuntu|debian)
            if apt-get update -y &>/dev/null; then
                echo "[V] Updated via apt"
            else
                echo "[X] Update failed"
            fi
        ;;
        rhel|centos|fedora)
            if command -v dnf &>/dev/null; then
                if dnf up -y; then
                    echo "[V] Updated via dnf"
                else
                    echo "[X] Update failed"
                fi
            else
                if yum update -y &>/dev/null; then
                    echo "[V] Updated via yum"
                else
                    echo "[X] Update failed"
                fi
            fi
        ;;
        arch|manjaro)
            if pacman -Syu --noconfirm &>/dev/null; then
                echo "[V] Updated via pacman"
            else
                echo "[X] Update failed"
            fi
        ;;
        *)
            echo "Unsupported distro: $distro"
        ;;
    esac
}

# ===== Create blue team users =====
make_blue_users() {
    
    # Create Personal User
    if ! id "$personal_user" &>/dev/null; then
        echo "[*] Creating personal user: $personal_user"
        adduser --disabled-password --comment "" "$personal_user"
    fi
    
    # Create Backup User
    if ! id "$backup_user" &>/dev/null; then
        echo "[*] Creating backup user: $backup_user"
        adduser --disabled-password --comment "" "$backup_user"
    fi
    
    # Grant sudo privileges
    echo "[*] Adding both users to the sudo group..."
    usermod -aG sudo "$personal_user"
    usermod -aG sudo "$backup_user"
    
    echo "[Completed user creation]"
}

change_passwords() {
    echo "[*] Changing passwords..."
    
    if [ "$headless" = false ]; then
        "$script_dir/passwords/change_all_passwords.sh" $excluded_from_pw_change
    else
        if [ -z "$headless_pass" ]; then
            echo "[X] Headless mode requires 'headless_pass' in config.env"
            exit 1
        else
            "$script_dir/passwords/change_all_passwords.sh" -l -p "$headless_pass"
            unset headless_pass
        fi
    fi
}

sshd_set() {
    local key="$1"
    local val="$2"
    if grep -q "^$key" /etc/ssh/sshd_config; then
        sed -i "s/^$key.*/$key $val/" /etc/ssh/sshd_config
    else
        echo "$key $val" >> /etc/ssh/sshd_config
    fi
}

harden_ssh() {
    echo "[*] Hardening sshd_config"
    
    sshd_set "PermitRootLogin" "no"
    sshd_set "MaxAuthTries" "3"
    sshd_set "PermitEmptyPasswords" "no"
    sshd_set "X11Forwarding" "no"
    sshd_set "IgnoreRhosts" "yes"
    sshd_set "HostbasedAuthentication" "no"
    
    systemctl restart sshd || systemctl restart ssh
    
    echo "[V] Done hardening sshd_config"
}

# ===== Only run as root =====
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Exiting..."
    exit 1
fi

OPTS=$(getopt -o "l" --long "headless" -n "$0" -- "$@")

eval set -- "$OPTS"

headless=false

while true; do
    case "$1" in
        -l|--headless)
            headless=true
            shift
        ;;
        --)
            shift
            break
        ;;
        *)
        ;;
    esac
done

update_system
make_blue_users
change_passwords
harden_ssh
"$script_dir/hardening/history_timestamps.sh"
if [ "$headless" = true ]; then
    "$script_dir/firewall/nft_config.sh" -l -ifa
else
    "$script_dir/firewall/nft_config.sh" -ifa
fi

echo "[V] Initialization complete at $(date) on $(hostname)"
# Blue Team Init

`init.sh` is the main entrypoint for rapidly hardening a Linux system during competitions or initial setup.

## 🔧 Usage

```bash
sudo ./init.sh         # Interactive mode
sudo ./init.sh -l      # Headless mode (uses config.env)
```

## ⚙️ Setup
### 🔐 config.env

Create this file in the same directory as init.sh:
```
headless_pass="YourSecurePasswordHere"
excluded_from_pw_change="user1 user2 user3..."
```

Used for automated password resets in headless mode.
### 🔥 firewall/default_rules.conf

Customize firewall behavior here (used by nft_config.sh):

    Open/close ports

    Set default policies

## 🧩 What It Does

    Updates system packages

    Creates sockpuppet and puppetmaster users

    Locks and resets passwords (with exclusions)

    Hardens SSH settings

    Applies nftables firewall

    Logs to ./blue_init.log

    Cleans up config.env after use

## 📁 Key Files

init.sh                  # Main script
config.env               # Headless password input
firewall/default_rules.conf
passwords/change_all_passwords.sh

## 💬 Made by MeHungr

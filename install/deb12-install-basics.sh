#!/bin/bash

# Check if script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo or run as root."
    exit 1
fi

# apt installation
echo "update & upgrade apps"
apt update & apt upgrade -y > /dev/null 2>&1

apt install -y git vim sudo curl wget > /dev/null 2>&1

# Sudo config
usermod -aG sudo debian




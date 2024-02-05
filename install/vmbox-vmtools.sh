#!/bin/bash

# Check if script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo or run as root."
    exit 1
fi


echo "Mouting..."
mkdir /mtn > /dev/null 2>&1
mount /dev/cdrom /mnt > /dev/null 2>&1
echo "Mount done. \n\n"
echo "Installing..."
apt install dkms linux-headers-$(uname -r) build-essential > /dev/null 2>&1
sh /mtn/VBoxLinuxAdditions.run > /dev/null 2>&1

echo "Installation ok."

unmount /dev/cdrom /mnt > /dev/null 2>&1
echo "Please reboot."
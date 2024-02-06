#!/bin/bash

# Check if script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo or run as root."
    exit 1
fi


# no display output
# > /dev/null 2>&1


# ==== Installation part ====
apt-get update > /dev/null 2>&1
apt-get upgrade -y > /dev/null 2>&1

apt -y install ca-certificates wget net-tools gnupg > /dev/null 2>&1
wget https://as-repository.openvpn.net/as-repo-public.asc -qO /etc/apt/trusted.gpg.d/as-repository.asc > /dev/null 2>&1

echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/as-repository.asc] http://as-repository.openvpn.net/as/debian bookworm main">/etc/apt/sources.list.d/openvpn-as-repo.list 

apt update && apt -y install openvpn-as > /dev/null 2>&1

cat /usr/local/openvpn_as/init.log


# ==== Configuration part ====
echo "Configuration..."
cd /usr/local/openvpn_as/scripts/

DEFAULT_ADMIN="Op3n4dmin"
DEFAULT_PASSW="4dmin2024"
DEFAULT_GROUP="default_group"
ADMIN_GROUP="admins_group"

# Create new user
adduser --gecos "$DEFAULT_ADMIN" "$DEFAULT_PASSW"
echo "$DEFAULT_ADMIN:$DEFAULT_PASSW" 

sh sacli --user  --key "type" --value "user_connect" UserPropPut # declare user for 
sh sacli --user "$DEFAULT_ADMIN" --new_pass "$DEFAULT_PASSW" SetLocalPassword


# create default groups
sh sacli --user "$DEFAULT_GROUP" --key "type" --value "group" UserPropPut
sh sacli --user "$DEFAULT_GROUP" --key "group_declare" --value "true" UserPropPut

sh sacli --user "$ADMIN_GROUP" --key "type" --value "group" UserPropPut
sh sacli --user "$ADMIN_GROUP" --key "group_declare" --value "true" UserPropPut # set this group as admin
sh sacli --user "$ADMIN_GROUP" --key "prop_superuser" --value "true" UserPropPut

# Add user to admin group 
sh sacli --user "$DEFAULT_ADMIN" --key "conn_group" --value "$ADMIN_GROUP" UserPropPut

# Setup MFA for default group
sh sacli --user "$DEFAULT_GROUP" --key "prop_google_auth" --value "true" UserPropPut
sh sacli --user "$ADMIN_GROUP" --key "prop_google_auth" --value "true" UserPropPut

sh sacli start


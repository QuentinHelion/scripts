#!/bin/bash

###########################################################################
# Author: 	    Quentin Hélion
# Date:   	    05/03/2024 (dd/mm/yyyy)
# Description: 	This script does install and config NextCloud and Dolibarr.
#               Apache2 - PHP
###########################################################################

# Variables
DB_ROOT_PASSWORD="root"
DB_USER="root"
DB_PASSWORD="root"
DB_HOST="localhost"
DB_NAME_NEXTCLOUD="NEXTCLOUD"
DB_NAME_DOLIBARR="DOLIBARR"


DOMAIN_NEXTCLOUD="nextcloud.homelab.lan"
DOCUMENT_ROOT_NEXTCLOUD="/var/www/nextcloud"

DOMAIN_DOLIBARR="dolibarr.homelab.lan"
DOCUMENT_ROOT_DOLIBARR="/var/www/nextcloud"


# Check if script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo or run as root."
    exit 1
fi

# Check if $1 exists
if [ -z "$1" ]; then
	display_help
	exit 1
fi

# Help function
display_help() {
    echo "Usage: $0 [-h] [-i ] [-r]"
    echo "  -h: Display this help message"
    echo "  -i | --install"
    echo "  -r | --reinstall"
    exit 0;
}


install_all() {

    # Update & Upgrade
    apt update -y && apt upgrade -y >> /dev/null

    # Install tools
    apt install -y wget unzip net-tools >> /dev/null

    # Install MySQL & apache 2
    apt install -y apache2 mariadb-server >> /dev/null

    # Install php with dependencies
    apt install -y php8.2 php8.2-cli php8.2-common php8.2-curl php8.2-gd php8.2-intl php8.2-mbstring php8.2-mysql php8.2-soap php8.2-xml php8.2-xmlrpc php8.2-zip php8.2-fpm php8.2-imap >> /dev/null


    # MySQL setup
    # mysql_secure_installation 

    mysql -u root -p"$DB_ROOT_PASSWORD" -e
        "CREATE DATABASE $DB_NAME_NEXTCLOUD;
        CREATE DATABASE $DB_NAME_DOLIBARR;
        GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost';
        FLUSH PRIVILEGES;"


    # NextCloud Installation
    cd /tmp
    wget https://download.nextcloud.com/server/releases/latest.zip
    unzip latest.zip
    mv nextcloud/ /var/www/
    chown -R www-data:www-data $DOMAIN_NEXTCLOUD

    # Create a virtual host configuration file
    touch /etc/apache2/sites-available/$DOMAIN_NEXTCLOUD.conf
    echo "<VirtualHost *:80>
        ServerAdmin webmaster@$DOMAIN_NEXTCLOUD
        ServerName $DOMAIN_NEXTCLOUD
        DocumentRoot $DOCUMENT_ROOT_NEXTCLOUD

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined

        <Directory $DOCUMENT_ROOT_NEXTCLOUD>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>
    </VirtualHost>" >> /etc/apache2/sites-available/$DOMAIN_NEXTCLOUD.conf


    # Dolibarr Installation
    cd /var/www
    wget https://github.com/Dolibarr/dolibarr/archive/refs/tags/19.0.0.zip
    unzip 19.0.0.zip
    mv dolibarr-19.0.0.zip/ dolibarr/
    chown -R www-data:www-data $DOCUMENT_ROOT_DOLIBARR

    # Create a virtual host configuration file
    touch /etc/apache2/sites-available/$DOMAIN_DOLIBARR.conf
    echo "<VirtualHost *:80>
            ServerName $DOMAIN_DOLIBARR
            DocumentRoot $DOCUMENT_ROOT_DOLIBARR/htdocs/

            <Directory $DOCUMENT_ROOT_DOLIBARR/htdocs>
                AllowOverride All
            </Directory>

            ErrorLog ${APACHE_LOG_DIR}/error.lo
            CustomLog ${APACHE_LOG_DIR}/access.log combined
            </VirtualHost>" >> /etc/apache2/sites-available/$DOMAIN_DOLIBARR.conf


    a2enmod headers env rewrite
    cd /etc/apache2/sites-available/
    a2dissite 000-default.conf
    a2ensite $DOMAIN_DOLIBARR.conf
    a2ensite $DOMAIN_NEXTCLOUD.conf
    systemctl restart apache2
}

uninstall_all() {

    cd /var/www/
    rm -rf nextcloud/ dolibarr/

    mysql -u root -p"$DB_ROOT_PASSWORD" -e
        "DROP DATABASE $DB_NAME_NEXTCLOUD;
        DROP DATABASE $DB_NAME_DOLIBARR;"

    a2dismod headers env rewrite
    cd /etc/apache2/sites-available/
    a2dissite $DOMAIN_DOLIBARR.conf
    a2dissite $DOMAIN_NEXTCLOUD.conf
    systemctl restart apache2
}

# Process command-line arguments
case "$1" in 
    -i | --install) # check if -i option exist
        install_all
        shift 2
    ;;
    -r | --reinstall) # check if -r option exist
        uninstall_all
        install_all
        shift 2
    ;;
    -h | --help) # check if -h option exist
        display_help  
        exit 0
    ;;
    *) # else 
        echo "Unknown option: $1"
        display_help
        exit 1
    ;;
esac


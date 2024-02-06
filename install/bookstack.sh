#!/bin/bash
# Script Name : InstallBookS.sh
# Description : A script to fully set up BookStack in HTTPS with a working CACHE server and a
daily, weekly
# and monthly automated backup
# Param 1 : Mysql DB name
# Param 2 : Mysql username
# Param 3 : Mysql user's Password
# Param 4 : Email address of sender
# Param 5 : Email password
# Ex) : ./InstallBookS db user passwd email email_passwd
# Authors : Saad Eddine OMARY && Quentin HELION
# Last Edit : 14/05/2023
########################################## VARIABLES ##########################################
# Get system primary user
user=$(id -un 1000)
# DB INFO
db=$1
dbUser="'$2'"
dbPasswd="'$3'"
# BookStack folder in user home folder
BookSFolder=/home/$user/BookStack
# Server Data
SrvIP=$(hostname -I)
SrvName=wiki-saad-quen.fr
# BookStack and BookStack related packages installation logs folders
mkdir /root/BookStack /root/BookStack/Logs /root/BookStack/Repo
mkdir $BookSFolder
#Edit /etc/hosts
echo $SrvIP $SrvName wiki >> /etc/hosts
Script
########################################## PACKAGES INSTALLATION
##########################################
# Install packages and write specific outputs to log files
# USEFUL PACKAGES
apt install git bat -y
# BOOKSTACK REQUIREMENTS
# Web related packages
apt install apache2 lynx -y | tee -a /root/BookStack/Logs/web.log
# PHP
# To install php v8+ we need to add Sury PHP repo to APT
apt-get install gnupg2 ca-certificates apt-transport-https software-properties-common -y
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list
wget -qO - https://packages.sury.org/php/apt.gpg | apt-key add -
apt-get update -y
#Now we can install php 8.2 and all necessary extensions for BookStack
apt install php8.2 php-fpm php-mbstring php-tokenizer php-gd php-xml php-curl php-mysql
libapache2-mod-fcgid libapache2-mod-php -y | tee -a /root/BookStack/Logs/php.logs
# DB
apt install mariadb-server -y | tee -a /root/BookStack/Logs/DB.logs
# Composer
apt install composer -y |tee -a /root/BookStack/Logs/composer.log
# CERTBOT FOR HTTPS
apt install certbot python3-certbot-apache -y
# CACHE SERVER / AutoMYSQLBackup / PDF RENDERING PLUGIN
apt install redis automysqlbackup wkhtmltopdf -y
########################################## CONFIGURATION
##########################################
# Setup DB
mysql -u root << EOF
create database $db;
grant all on $db.* to $dbUser@'localhost' identified by $dbPasswd;
FLUSH PRIVILEGES;
EOF
# Clone BookStack Git Repo
git clone https://github.com/BookStackApp/BookStack.git --branch release --single-branch
$BookSFolder
# Permissioooons!!!
chown -R $user:$user $BookSFolder
chown -R www-data:www-data $BookSFolder/storage
chown -R www-data:www-data $BookSFolder/public/uploads
chown -R www-data:www-data $BookSFolder/bootstrap/cache
chmod -R 755 bootstrap/cache public/uploads storage
# Install Composer
cd $BookSFolder
echo -e "yes\n" |composer install --no-dev
### Edit the .env file
cp -v .env.example .env
# For HTTPS
sed -i 's|https://example.com|https://wiki-saad-quen.fr|' $BookSFolder/.env
# DB Info
sed -i "s|database_database|$1|" $BookSFolder/.env
sed -i "s|database_username|$2|" $BookSFolder/.env
sed -i "s|database_user_password|$3|" $BookSFolder/.env
# SMTP Relay
sed -i "s|bookstack@example.com|$4|" $BookSFolder/.env
sed -i "s|MAIL_HOST=localhost|MAIL_HOST=smtp.zoho.eu|" $BookSFolder/.env
sed -i "s|1025|587|" $BookSFolder/.env
sed -i "s|MAIL_USERNAME=null|MAIL_USERNAME=$4|" $BookSFolder/.env
sed -i "s|MAIL_PASSWORD=null|MAIL_PASSWORD=$5|" $BookSFolder/.env
sed -i "s|MAIL_ENCRYPTION=null|MAIL_ENCRYPTION=tls|" $BookSFolder/.env
# REDIS
echo "# Set both the cache and session to use Redis" >> $BookSFolder/.env
echo "CACHE_DRIVER=redis" >> $BookSFolder/.env
echo "SESSION_DRIVER=redis" >> $BookSFolder/.env
echo "# Specify REDIS server and port" >> $BookSFolder/.env
echo "REDIS_SERVERS=127.0.0.1:6379:0" >> $BookSFolder/.env
# PDF Rendering Plugin
echo "# PDF RENDERING PLUGIN" >> $BookSFolder/.env
echo "ALLOW_UNTRUSTED_SERVER_FETCHING=true" >> $BookSFolder/.env
echo "APP_PDF_GENERATOR=wkhtmltopdf" >> $BookSFolder/.env
echo -e 'yes\n'|php artisan key:generate
echo -e 'yes\n'|php artisan migrate:refresh
mv $BookSFolder /var/www
cat > /etc/apache2/sites-available/bookstack.conf << EOF
 ServerName wiki-saad-quen.fr
 ServerAdmin webmaster@localhost
 DocumentRoot /var/www/BookStack/public/

 Options Indexes FollowSymLinks
 AllowOverride None
 Require all granted


 Options -MultiViews -Indexes

 RewriteEngine On
 # Handle Authorization Header
 RewriteCond %{HTTP:Authorization} .
 RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
 # Redirect Trailing Slashes If Not A Folder...
 RewriteCond %{REQUEST_FILENAME} !-d
 RewriteCond %{REQUEST_URI} (.+)/$
 RewriteRule ^ %1 [L,R=301]
 # Handle Front Controller...
 RewriteCond %{REQUEST_FILENAME} !-d
 RewriteCond %{REQUEST_FILENAME} !-f
 RewriteRule ^ index.php [L]


 ErrorLog ${APACHE_LOG_DIR}/error.log
 CustomLog ${APACHE_LOG_DIR}/access.log combined
EOF
cd /etc/apache2/sites-available
/usr/sbin/a2enmod rewrite
/usr/sbin/a2enmod actions fcgid alias proxy_fcgi
systemctl restart php8.2-fpm
/usr/sbin/a2ensite bookstack.conf
/usr/sbin/apachectl configtest
/usr/sbin/a2dissite 000-default.conf
systemctl restart apache2
########################################## FINAL STEPS ##########################################
# Test Connectivity
ping -c4 $SrvName
# A 2s sleep because why not ?
sleep 2
# Run Certbot to set up HTTPS on your web server
certbot
# For AutoMYSQLBackup : check SQL backup page

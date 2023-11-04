#!/bin/bash

# KEY GENERATION
APP_KEY=$(openssl rand -hex 16)

# Database Configuration Parameters
DB_NAME=snipeitdb
DB_USER=snipeituser
DB_PASSWORD=snipeitpass

sudo apt update
sudo apt install git apache2 -y
sudo systemctl start apache2 && sudo systemctl enable apache2
sudo a2enmod rewrite
sudo systemctl restart apache2
sudo apt install mariadb-server mariadb-client -y
sudo systemctl start mariadb && sudo systemctl enable mariadb

#mysql_secure_installation automated

sudo apt install expect -y

SECURE_MYSQL=$(expect -c "
set timeout 5
spawn sudo mysql_secure_installation
expect \"Enter current password for root : \"
send \"\r\"
expect \"Switch to unix_socket authentication\"
send \"n\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

echo "$SECURE_MYSQL"

sudo apt install -y php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath php-bz2 php-intl php-opcache php-pdo php-calendar php-ctype php-exif php-ffi php-fileinfo php-ftp php-iconv php-mysqli php-phar php-posix php-readline php-shmop php-sockets php-sysvmsg php-sysvsem php-sysvshm php-tokenizer php-curl php-ldap

sudo curl -sS https://getcomposer.org/installer | php

sudo mv composer.phar /usr/local/bin/composer

#Database Configuration
sudo mysql -u root -e "CREATE DATABASE snipeitdb;"
sudo mysql -u root -e "CREATE USER snipeituser@localhost IDENTIFIED BY 'snipeitpass';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON snipeitdb.* TO snipeituser@localhost;"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

cd /var/www/
sudo git clone https://github.com/snipe/snipe-it snipe-it
cd snipe-it

sudo cp .env.example .env
sudo sed -i "s|^\\(DB_DATABASE=\\).*|\\1$DB_NAME|" "/var/www/snipe-it/.env"
sudo sed -i "s|^\\(DB_USERNAME=\\).*|\\1$DB_USER|" "/var/www/snipe-it/.env"
sudo sed -i "s|^\\(DB_PASSWORD=\\).*|\\1$DB_PASSWORD|" "/var/www/snipe-it/.env"
sudo sed -i "s|^\\(APP_URL=\\).*|\\1|" "/var/www/snipe-it/.env"
sudo sed -i "s|^\\(APP_KEY=\\).*|\\1$APP_KEY|" "/var/www/snipe-it/.env"

sudo chown -R www-data:www-data /var/www/snipe-it
sudo chmod -R 755 /var/www/snipe-it

export COMPOSER_ALLOW_SUPERUSER=1

sudo composer -n update --no-plugins --no-scripts

sudo composer -n install --no-dev --prefer-source --no-plugins --no-scripts


sudo a2dissite 000-default.conf

cat << EOF > /etc/apache2/sites-available/snipe-it.conf
<VirtualHost *:80>
  ServerName pspradhan.cloud
  DocumentRoot /var/www/snipe-it/public
  <Directory /var/www/snipe-it/public>
    Options Indexes FollowSymLinks MultiViews
    AllowOverride All
    Order allow,deny
    allow from all
  </Directory>
</VirtualHost>
EOF

sudo a2ensite snipe-it.conf

sudo chown -R www-data:www-data ./storage
sudo chmod -R 755 ./storage

sudo systemctl restart apache2

sudo apt purge expect -y
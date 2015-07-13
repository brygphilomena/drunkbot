#!/bin/bash
echo "Updating"
sudo apt-get update -qq >/dev/null
echo "Upgrading"
sudo apt-get upgrade -y >> /dev/null

echo "Installing dependencies"
echo "Nginx and curl"
sudo apt-get install nginx curl -y >/dev/null	 
echo "PHP5"
sudo apt-get install php5-fpm php5-cgi php5-cli php5-common php5-mcrypt -y >/dev/null
echo "sqlite"
sudo apt-get install sqlite sqlite3 libsqlite3-dev php5-sqlite -y >/dev/null
echo "avahi-daemon"
sudo apt-get install avahi-daemon

echo "Changing host"
sudo sed -i '$ d' /etc/hosts
sudo echo "127.0.1.1	drink-maker" >> /etc/hosts

echo "Changing hostname"
sudo echo "drink-maker" > /etc/hostname

echo "Creating usergroup www-data"
sudo useradd www-data 
sudo groupadd www-data 
sudo usermod -g www-data www-data 
sudo mkdir -p /var/www 
sudo chmod 775 /var/www -R 
sudo chown www-data:www-data /var/www 

echo "Setting up Nginx"
sudo rm /etc/nginx/sites-available/default
sudo cp install/default /etc/nginx/sites-available/default
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

sudo rm /etc/php5/fpm/pool.d/www.conf
sudo cp install/www.conf /etc/php5/fpm/pool.d/www.conf

sudo rm /etc/php5/fpm/php.ini
sudo cp install/php.ini /etc/php5/fpm/php.ini

echo "Restarting services and enabling mcrypt"
sudo php5enmod mcrypt
sudo service php5-fpm restart
sudo service nginx restart

echo "Installing composer"
cd install
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
cd ..

echo "Changing environment"
sudo rm /home/pi/drink-maker/.env
sudo cp /home/pi/drink-maker/.env.deploy /home/pi/drink-maker/.env

echo "Moving all in /var/www"
sudo mkdir /var/www/drink-maker
sudo cp -R /home/pi/drink-maker /var/www/drink-maker
sudo chown www-data:www-data /var/www/drink-maker -R
sudo chmod 0775 /var/www/drink-maker/storage -R

echo "Deleting everything from install path"
sudo rm -rf /home/pi/drink-maker

echo "Installing composer dependencies"
cd /var/www/drink-maker
sudo -u www-data -H touch storage/database.sqlite
sudo -u www-data -H composer install

echo "Migrating and seeding"
sudo -u www-data -H php artisan migrate --seed --force

echo "Adding python to startup"
sudo cp /var/www/drink-maker/utils/drink-makerController.sh /etc/init.d/drink-maker.sh
sudo chmod +x /etc/init.d/drink-maker.sh

echo "Enjoy!"

sudo reboot
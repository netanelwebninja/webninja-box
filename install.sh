#!/bin/bash

# /*=================================
# =            VARIABLES            =
# =================================*/
INSTALL_NGINX_INSTEAD=1
WELCOME_MESSAGE='

 _  _  _  _______  ______   ______   _           _           ______                
| || || |(_______)(____  \ |  ___ \ (_)         (_)         (____  \               
| || || | _____    ____)  )| |   | | _  ____     _   ____    ____)  )  ___   _   _ 
| ||_|| ||  ___)  |  __  ( | |   | || ||  _ \   | | / _  |  |  __  (  / _ \ ( \ / )
| |___| || |_____ | |__)  )| |   | || || | | |  | |( ( | |  | |__)  )| |_| | ) X ( 
 \______||_______)|______/ |_|   |_||_||_| |_| _| | \_||_|  |______/  \___/ (_/ \_)
                                              (__/                                 

*------------------------*
Happy development :-) ---*
WEBNinja. ---------------*
*------------------------*
'

reboot_webserver_helper() {

    if [ $INSTALL_NGINX_INSTEAD != 1 ]; then
        sudo service apache2 restart
    fi

    if [ $INSTALL_NGINX_INSTEAD == 1 ]; then
        sudo systemctl restart php7.2-fpm
        sudo systemctl restart nginx
    fi

    echo 'Rebooting your webserver'
}





# /*=========================================
# =            CORE / BASE STUFF            =
# =========================================*/
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get install -y software-properties-common
sudo apt-add-repository ppa:nginx/development -y
sudo apt-add-repository ppa:chris-lea/redis-server -y
sudo apt-add-repository ppa:ondrej/php -y
sudo apt-get update

sudo apt-get install -y build-essential tcl curl fail2ban gcc git vim libmcrypt4 libpcre3-dev make python2.7 python-pip sendmail supervisor ufw unattended-upgrades unzip whois zsh

# /*=====================================
# =            INSTALL NGINX            =
# =====================================*/
if [ $INSTALL_NGINX_INSTEAD == 1 ]; then

    # Install Nginx
    sudo apt-get -y install nginx
    sudo systemctl enable nginx

    # Remove "html" and add public
    mv /var/www/html /var/www/public

    # Make sure your web server knows you did this...
    MY_WEB_CONFIG='server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/public;
        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
            try_files $uri $uri/ =404;
        }
    }'
    echo "$MY_WEB_CONFIG" | sudo tee /etc/nginx/sites-available/default

    sudo systemctl restart nginx

fi




# /*===================================
# =            INSTALL PHP            =
# ===================================*/
sudo apt-get install -y php7.2-cli php7.2-dev \
php7.2-pgsql php7.2-sqlite3 php7.2-gd \
php7.2-curl php7.2-memcached \
php7.2-imap php7.2-mysql php7.2-mbstring \
php7.2-xml php7.2-zip php7.2-bcmath php7.2-soap \
php7.2-intl php7.2-readline

# Make PHP and NGINX friends
if [ $INSTALL_NGINX_INSTEAD == 1 ]; then

    # FPM STUFF
    sudo apt-get -y install php7.2-fpm
    sudo systemctl enable php7.2-fpm
    sudo systemctl start php7.2-fpm

    # Fix path FPM setting
    echo 'cgi.fix_pathinfo = 0' | sudo tee -a /etc/php/7.2/fpm/conf.d/user.ini
    sudo systemctl restart php7.2-fpm

    # Add index.php to readable file types and enable PHP FPM since PHP alone won't work
    MY_WEB_CONFIG='server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/public;
        index index.php index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
            try_files $uri $uri/ =404;
        }

        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/run/php/php7.2-fpm.sock;
        }

        location ~ /\.ht {
            deny all;
        }
    }'
    echo "$MY_WEB_CONFIG" | sudo tee /etc/nginx/sites-available/default

cat > /etc/nginx/conf.d/gzip.conf << EOF
gzip_comp_level 5;
gzip_min_length 256;
gzip_proxied any;
gzip_vary on;

gzip_types
application/atom+xml
application/javascript
application/json
application/rss+xml
application/vnd.ms-fontobject
application/x-font-ttf
application/x-web-app-manifest+json
application/xhtml+xml
application/xml
font/opentype
image/svg+xml
image/x-icon
text/css
text/plain
text/x-component;

EOF

    sudo systemctl restart nginx

fi

# /*===========================================
# =            CUSTOM PHP SETTINGS            =
# ===========================================*/
if [ $INSTALL_NGINX_INSTEAD == 1 ]; then
    PHP_USER_INI_PATH=/etc/php/7.2/fpm/conf.d/user.ini
else
    PHP_USER_INI_PATH=/etc/php/7.2/apache2/conf.d/user.ini
fi

echo 'display_startup_errors = On' | sudo tee -a $PHP_USER_INI_PATH
echo 'display_errors = On' | sudo tee -a $PHP_USER_INI_PATH
echo 'error_reporting = E_ALL' | sudo tee -a $PHP_USER_INI_PATH
echo 'short_open_tag = On' | sudo tee -a $PHP_USER_INI_PATH
reboot_webserver_helper

# Disable PHP Zend OPcache
echo 'opache.enable = 0' | sudo tee -a $PHP_USER_INI_PATH

# Absolutely Force Zend OPcache off...
if [ $INSTALL_NGINX_INSTEAD == 1 ]; then
    sudo sed -i s,\;opcache.enable=0,opcache.enable=0,g /etc/php/7.2/fpm/php.ini
else
    sudo sed -i s,\;opcache.enable=0,opcache.enable=0,g /etc/php/7.2/apache2/php.ini
fi
reboot_webserver_helper


# /*=============================
# =            MYSQL            =
# =============================*/
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
sudo apt-get -y install mysql-server
sudo mysqladmin -uroot -proot create webninja
reboot_webserver_helper


# /*=================================
# =            PostreSQL            =
# =================================*/
sudo apt-get -y install postgresql postgresql-contrib
echo "CREATE ROLE root WITH LOGIN ENCRYPTED PASSWORD 'root';" | sudo -i -u postgres psql
sudo -i -u postgres createdb --owner=root webninja
reboot_webserver_helper

# /*==============================
# =            SQLITE            =
# ===============================*/
sudo apt-get -y install sqlite
reboot_webserver_helper



# /*================================
# =            COMPOSER            =
# ================================*/
EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")
php composer-setup.php --quiet
rm composer-setup.php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod 755 /usr/local/bin/composer



# /*==================================
# =            BEANSTALKD            =
# ==================================*/
sudo apt-get install -y beanstalkd
sudo sed -i "s/BEANSTALKD_LISTEN_ADDR.*/BEANSTALKD_LISTEN_ADDR=0.0.0.0/" /etc/default/beanstalkd
sudo sed -i "s/#START=yes/START=yes/" /etc/default/beanstalkd

sudo service beanstalkd start
sleep 5
sudo service beanstalkd restart


# /*==================================
# =            Supervisor            =
# ==================================*/
sudo systemctl enable supervisor.service
sudo service supervisor start


# /*=============================
# =            NGROK            =
# =============================*/
sudo apt-get install ngrok-client

# /*==============================
# =            NODEJS            =
# ==============================*/
sudo apt-get -y install nodejs
sudo apt-get -y install npm

# Use NVM though to make life easy
wget -qO- https://raw.github.com/creationix/nvm/master/install.sh | bash
source ~/.nvm/nvm.sh
nvm install 6.10.3

# Node Packages
sudo npm install -g gulp
sudo npm install -g grunt
sudo npm install -g bower
sudo npm install -g yo
sudo npm install -g browser-sync
sudo npm install -g browserify
sudo npm install -g pm2
sudo npm install -g webpack

# /*============================
# =            YARN            =
# ============================*/
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update
sudo apt-get -y install yarn


# /*============================
# =            RUBY            =
# ============================*/
sudo apt-get -y install ruby
sudo apt-get -y install ruby-dev

# Use RVM though to make life easy
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm install 2.4.1
rvm use 2.4.1


# /*=============================
# =            REDIS            =
# =============================*/
sudo apt-get -y install redis-server
sudo sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
sudo service redis-server restart
reboot_webserver_helper



# /*=================================
# =            MEMCACHED            =
# =================================*/
sudo apt-get -y install memcached
sudo sed -i 's/-l 127.0.0.1/-l 0.0.0.0/' /etc/memcached.conf
sudo service memcached restart
reboot_webserver_helper

# /*=================================
# =           Laravel Project       =
# =================================*/
composer global require "laravel/installer"
sudo echo 'export PATH="~/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
cd /var/www
sudo laravel new project
sudo rm -rf README.md .gitignore public/
sudo mv project/* project/.[^.]* .
sudo rm -rf project
sudo sed -i -e 's/DB_USERNAME=homestead/DB_USERNAME=root/g' .env
sudo sed -i -e 's/DB_USERNAME=homestead/DB_PASSWORD=root/g' .env
sudo sed -i -e 's/DB_USERNAME=homestead/DB_DATABASE=webninja/g' .env
                        

# /*=======================================
# =            WELCOME MESSAGE            =
# =======================================*/

# Disable default messages by removing execute privilege
sudo chmod -x /etc/update-motd.d/*

# Set the new message
echo "$WELCOME_MESSAGE" | sudo tee /etc/motd


# /*====================================
# =            YOU ARE DONE            =
# ====================================*/
echo 'Booooooooom! We are done. Go make some great things ninja.'
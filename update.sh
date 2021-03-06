#!/bin/bash
################################################################################
# Original Author:   crombiecrunch
# Fork Author: manfromafar
# Current Author: RealAwesomeness (https://github.com/RealAwesomeness/yiimp-install-script)
# Web:     
#
# Program:
#   Install yiimp on Ubuntu 16.04 running Nginx, MariaDB, and php7.0.x
# 
# 
################################################################################
output() {
    printf "\E[0;33;40m"
    echo $1
    printf "\E[0m"
}

displayErr() {
    echo
    echo $1;
    echo
    exit 1;
}

    output " "
    output "Make sure you double check before hitting enter! Only one shot at these!"
    output " "
    read -e -p "Server name (no http:// or www. just : example.com or pool.example.com) : " server_name
    read -e -p "Are you using a subdomain (pool.example.com?) [y/N] : " sub_domain
    read -e -p "Enter support email (e.g. admin@example.com) : " EMAIL
    read -e -p "Set Pool to AutoExchange? i.e. mine any coin with BTC address? [y/N] : " BTC
    read -e -p "Please enter a new location for /site/adminRights this is to customize the Admin Panel entrance url (e.g. myAdminpanel) : " admin_panel
    read -e -p "Enter the Public IP of the system you will use to access the admin panel (http://www.whatsmyip.org/) : " Public
    
    
    # Update package and Upgrade Ubuntu
    output " "
    output "Updating system and installing required packages."
    output " "
    sleep 3
        
    sudo apt-get -y update 
    sudo apt-get -y upgrade
    sudo apt-get -y autoremove
    
    
    # Generating Random Passwords
    password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    password2=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    AUTOGENERATED_PASS=`pwgen -c -1 20`
    
    
    # Test Email
    output " "
    output "Testing to see if server emails are sent"
    output " "
    sleep 3
    
    if [[ "$root_email" != "" ]]; then
        echo $root_email > sudo tee --append ~/.email
        echo $root_email > sudo tee --append ~/.forward

    if [[ ("$send_email" == "y" || "$send_email" == "Y" || "$send_email" == "") ]]; then
        echo "This is a mail test for the SMTP Service." > sudo tee --append /tmp/email.message
        echo "You should receive this !" >> sudo tee --append /tmp/email.message
        echo "" >> sudo tee --append /tmp/email.message
        echo "Cheers" >> sudo tee --append /tmp/email.message
        sudo sendmail -s "SMTP Testing" $root_email < sudo tee --append /tmp/email.message

        sudo rm -f /tmp/email.message
        echo "Mail sent"
    fi
    fi
    
	
    # Installing Yiimp
    output " "
    output " Installing Yiimp"
    output " "
    output "Grabbing yiimp fron Github, building files and setting file structure."
    output " "
    sleep 3
    
    
    # Generating Random Password for stratum
    blckntifypass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    
    # Compile Blocknotify
    cd ~
    sudo rm -r yiimp
    git clone https://github.com/tpruvot/yiimp.git
    cd $HOME/yiimp/blocknotify
    sudo sed -i 's/tu8tu5/'$blckntifypass'/' blocknotify.cpp
    sudo make
    
    # Compile iniparser
    cd $HOME/yiimp/stratum/iniparser
    sudo make
    
    # Compile Stratum
    cd $HOME/yiimp/stratum
    if [[ ("$BTC" == "y" || "$BTC" == "Y") ]]; then
    sudo sed -i 's/CFLAGS += -DNO_EXCHANGE/#CFLAGS += -DNO_EXCHANGE/' $HOME/yiimp/stratum/Makefile
    sudo make
    fi
    sudo make
    
    # Copy Files (Blocknotify,iniparser,Stratum)
    sudo rm -r /var/assets
    sudo rm -r /var/extensions
    sudo rm -r /var/framework
    sudo rm -r /var/images
    sudo rm -r /var/yaamp
    sudo rm -r /var/stratum
    cd $HOME/yiimp
    sudo sed -i 's/AdminRights/'$admin_panel'/' $HOME/yiimp/web/yaamp/modules/site/SiteController.php
    yes | sudo cp -r $HOME/yiimp/web /var/
    sudo mkdir -p /var/stratum
    cd $HOME/yiimp/stratum
    yes | sudo cp -a config.sample/. /var/stratum/config
    yes | sudo cp -r stratum /var/stratum
    yes | sudo cp -r run.sh /var/stratum
    cd $HOME/yiimp
    yes | sudo cp -r $HOME/yiimp/bin/. /bin/
    yes | sudo cp -r $HOME/yiimp/blocknotify/blocknotify /usr/bin/
    yes | sudo cp -r $HOME/yiimp/blocknotify/blocknotify /var/stratum/
    sudo mkdir -p /etc/yiimp
    sudo mkdir -p /$HOME/backup/
    #fixing yiimp
    sed -i "s|ROOTDIR=/data/yiimp|ROOTDIR=/var|g" /bin/yiimp
    #fixing run.sh
    sudo rm -r /var/stratum/config/run.sh
    echo '
#!/bin/bash
ulimit -n 10240
ulimit -u 10240
cd /var/stratum
while true; do
./stratum /var/stratum/config/$1
sleep 2
done
exec bash
' | sudo -E tee /var/stratum/config/run.sh >/dev/null 2>&1
    sudo chmod +x /var/stratum/config/run.sh

    # Updating stratum config files with database connection info
    output " "
    output "Updating stratum config files with database connection info."
    output " "
    sleep 3
 
    cd /var/stratum/config
    sudo sed -i 's/password = tu8tu5/password = '$blckntifypass'/g' *.conf
    sudo sed -i 's/server = yaamp.com/server = '$server_name'/g' *.conf
    sudo sed -i 's/host = yaampdb/host = localhost/g' *.conf
    sudo sed -i 's/database = yaamp/database = yiimpfrontend/g' *.conf
    sudo sed -i 's/username = root/username = stratum/g' *.conf
    sudo sed -i 's/password = patofpaq/password = '$password2'/g' *.conf
    cd ~


    # Final Directory permissions
    output " "
    output "Final Directory permissions"
    output " "
    sleep 3

    whoami=`whoami`
    sudo mkdir /root/backup/
    #sudo usermod -aG www-data $whoami
    #sudo chown -R www-data:www-data /var/log
    sudo chown -R www-data:www-data /var/stratum
    sudo chown -R www-data:www-data /var/web
    sudo touch /var/log/debug.log
    sudo chown -R www-data:www-data /var/log/debug.log
    sudo chmod -R 775 /var/www/$server_name/html
    sudo chmod -R 775 /var/web
    sudo chmod -R 775 /var/stratum
    sudo chmod -R 775 /var/web/yaamp/runtime
    sudo chmod -R 664 /root/backup/
    sudo chmod -R 644 /var/log/debug.log
    sudo chmod -R 775 /var/web/serverconfig.php
    sudo rm -r $HOME/yiimp/
    sudo rm -rf /var/log/nginx/*
    sudo systemctl reload php7.0-fpm.service
    sudo systemctl restart nginx.service


    output " "
    output " "
    output " "
    output " "
    output "Whew that was fun, just some reminders. Your mysql information is saved in ~/.my.cnf. this installer did not directly install anything required to build coins."
    output " "
    output "Please make sure to change your wallet addresses in the /var/web/serverconfig.php file."
    output " "
    output "Please make sure to add your public and private keys."
    output " "
    output "TUTO Youtube : https://www.youtube.com/watch?v=vdBCw6_cyig"
    output " "
    output " "

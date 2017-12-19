#!/bin/bash
# Nginx Virtual Host Auto Installer
# Created by Teguh Aprianto
# https://bukancoder | https://teguh.co

IJO='\e[38;5;82m'
MAG='\e[35m'
RESET='\e[0m'

echo -e "$IJO                                                                                   $RESET"
echo -e "$IJO __________       __                    $MAG _________            .___             $RESET"
echo -e "$IJO \______   \__ __|  | _______    ____   $MAG \_   ___ \  ____   __| _/___________  $RESET"
echo -e "$IJO  |    |  _/  |  \  |/ /\__  \  /    \  $MAG /    \  \/ /  _ \ / __ |/ __ \_  __ \ $RESET"
echo -e "$IJO  |    |   \  |  /    <  / __ \|   |  \ $MAG \     \___(  <_> ) /_/ \  ___/|  | \/ $RESET"
echo -e "$IJO  |______  /____/|__|_ \(____  /___|  / $MAG  \______  /\____/\____ |\___  >__|    $RESET"
echo -e "$IJO        \/           \/     \/     \/   $MAG        \/            \/    \/         $RESET"
echo -e "$IJO ---------------------------------------------------------------------------       $RESET"
echo -e "$IJO |$MAG                    Nginx Virtual Host Auto Installer                    $IJO| $RESET"
echo -e "$IJO ---------------------------------------------------------------------------       $RESET"
echo -e "$IJO |$IJO                               Created by                                $IJO| $RESET"
echo -e "$IJO |$MAG                             Teguh Aprianto                              $IJO| $RESET"
echo -e "$IJO ---------------------------------------------------------------------------       $RESET"
echo ""

echo -e "$MAG--=[ To create a vhost for new domain, press any key to continue ]=--$RESET"
read answer 

echo -e "$MAG--=[ Adding domain to the server ]=--$IJO"
    domain="yourdomain.com"
	read -p "Domain to add : " domain
	if [ "$domain" = "" ]; then
		domain="yourdomain.com"
	fi
	if [ ! -f "/etc/nginx/sites-available/$domain.conf" ]; then
	echo "---------------------------"
	echo "Domain : $domain"
	echo "---------------------------" 
	else
	echo "---------------------------"
	echo "$domain is exist!"
	echo "---------------------------"	
	fi
echo
echo

echo -e "$MAG--=[ Create new user for the domain ]=--$IJO"
if [ $(id -u) -eq 0 ]; then
	read -p "Enter username : " username
	read -s -p "Enter password : " password
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$username exists!"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		useradd -m -p $pass $username
		[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
	fi
else
	echo "Only root may add a user to the system"
	exit 2
fi
	echo "---------------------------"
	echo "Username : $username"
	echo "---------------------------" 
echo
echo

echo -e "$MAG--=[Directory for the domain]=--$IJO "
vhostdir="/home/$username/www/$domain/public_html"
	read -p "Default directory: /home/$username/www/$domain/public_html : " vhostdir
	if [ "$vhostdir" = "" ]; then
		vhostdir="/home/$username/www/$domain/public_html"
	fi
	echo "------------------------------------------------------"
	echo Virtual Host Directory="$vhostdir"
	echo "------------------------------------------------------"
echo
echo
echo -e "$MAG--=[Adding new virtual host for the domain]=--$IJO"
echo -e "Press any key to start adding new virtual host $RESET"
read answer 
echo
echo

if [ ! -d /etc/nginx/sites-available/ ]; then
	mkdir /etc/nginx/sites-available/
fi

if [ ! -d /etc/nginx/sites-enabled/ ]; then
	mkdir /etc/nginx/sites-enabled/
fi


echo -e "$MAG--=[ Creating domain directory ]=--$IJO"
mkdir -p $vhostdir
chmod 775 $vhostdir
chmod 755 /home/$username 
chown $username:$username $vhostdir
chown $username:$username /home/$username 
chown $username:$username /home/$username/www
chown $username:$username /home/$username/www/$domain 
echo
echo
echo -e "$MAG--=[ Creating virtual host for domain $IJO $domain $MAG]=--$IJO"
fastcgi_script_name='$fastcgi_script_name'
cat >/etc/nginx/sites-available/$domain.conf<<eof
$alf
server {
    server_name  $domain;                     
    root   /home/$username/www/$domain/public_html;  
    error_log /home/$username/www/$domain/error.log;                       
    access_log /home/$username/www/$domain/access.log;            

    location / {
            index index.php  index.html index.htm;
    }
    location ~ .php$ {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_buffers 16 16k; 
        fastcgi_buffer_size 32k;
        fastcgi_param  SCRIPT_FILENAME  /home/$username/www/$domain/public_html$fastcgi_script_name;
        include        fastcgi_params;
    }
}

eof
echo
echo

echo -e "$MAG--=[ Creating symbolic link for the vhost ]=--$IJO"
ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/$domain.conf
echo
echo

echo -e "$MAG--=[ Creating new Nginx Configuration ]=--$IJO"
rm -rf /etc/nginx/nginx.conf 
cat >/etc/nginx/nginx.conf<<eof
$alf
user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;
    client_max_body_size 500M;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}

eof
echo
echo

echo -e "$MAG--=[ Test Nginx Configuration File ]=--$IJO"
nginx -t
echo
echo

echo -e "$MAG--=[ Creating PHP Info File ]=--$IJO"
cd /home/$username/www/$domain/public_html
cat > "info.php" <<EOF

<?php
phpinfo();
?>

EOF
chmod 775 info.php
echo
echo
echo -e "$MAG--=[ Restarting Nginx ]=--$IJO"
service nginx restart 

echo
echo -e "$MAG--=[Done! Domain $IJO http://$domain $MAG has been added to the server $MAG]=--$IJO"
echo -e "$MAG--=[PHP Info available on $IJO http://$domain/info.php $MAG]=--$RESET"


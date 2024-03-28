#!/bin/bash
# Script made by Romin Kleeman

#set -x

# Check whether script is run as root
# Comparing current run user with 0 since it's always the UID of root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

# Check whether there's atleast 1 given argument with script, else exit
if [ -z $1 ]; then
  echo -e "SYNOPSIS:\n\t${0:2} <configuratiebestand>"
  exit 22 # 22 is the exit code for invalid argument
elif ! [ -f $1 ]; then
  echo "Bestand $1 bestaat niet. Script afgebroken"
  exit 2; # Returns no such file or directory
fi

# Set array of dependencies for scalability
  # Added the php apache2 library since it was missing in the original script
services=( apache2 mariadb-server mariadb-client php php-mysql "libapache2-mod-php7.4" )
sysd_services=( apache2 mysql )
lines=(`wc -l $1`)

# Check whether conf file actually contains lines and set lines in array
if ! [[ $lines > 0 ]]; then
  echo "$1 is an empty config file, exiting..."
  exit;
else
  servers=(`cat $1`)
fi

# Check whether the servers are reachable through ssh, else exit
for server in "${servers[@]}"
do
  if ! nc -zv $server 22 &>/dev/null; then
    echo "Couldn't ssh to $server"
    exit 68 # exit code 68 used for "host doesn't exist"
  fi
done


echo "Installatie via configuratiebestand $1"
echo -e "Op de volgende servers wordt $service geinstalleerd en gestart:"
for server in "${servers[@]}"
do
  echo -e "\t- $server"
done

# Counter for amount of successful server installs
counter=0

# Check for each server if services are already installed, else install them
for server in "${servers[@]}"
do
  for service in "${services[@]}"
  do
    if [[ $(ssh $server dpkg-query -s $service 2>/dev/null | awk '/^Status:/ {print $NF}') != "installed" ]]; then
      echo "Installatie $service op server $server"
      ssh $server "apt install ${service} -y" &>/dev/null # Don't show output

      # Check if service is apache2, enable it and start it (--now starts the service)
      if [[ $service == "apache2" ]]; then
        ssh $server "systemctl enable --now apache2 && sudo ufw allow 'Apache'" &>/dev/null
      fi
      
      # Check if service is mariadb, enable it, start it and setup database for wordpress
      if [[ $service == "mariadb-client" ]]; then
  	ssh $server "systemctl enable --now mariadb
   	  mysql -e 'CREATE DATABASE wordpress_db;'
	  mysql -e 'CREATE USER \"wp_user\"@\"%\" IDENTIFIED BY \"password\";'
	  mysql -e 'GRANT ALL PRIVILEGES ON wordpress_db.* TO \"wp_user\"@\"%\";'
	  mysql -e 'FLUSH PRIVILEGES;'
	  systemctl restart mariadb --quiet" &>/dev/null
     fi

      # Enable php for apache2
      if [[ $service == "php" ]]; then
	ssh $server "a2enmod php && systemctl restart apache2" &>/dev/null
      fi

    else
       echo "$service is al geinstalleerd op server $server"
    fi
  done

  # Check if wp-content directory exists, if not, install wordpress 
  if ! ssh $server "test -d /var/www/html/wp-content" &>/dev/null; then
    echo "Installatie van wordpress op server $server"

    # Installatie van wordpress op remote server 
    ssh $server "cd /tmp && \
      wget https://wordpress.org/latest.tar.gz && \
      tar -xf latest.tar.gz && \
      cd /tmp/wordpress && \
      cp -R * /var/www/html/ && \
      chmod -R 755 /var/www/html/ && \
      mkdir /var/www/html/wp-content/uploads && \
      cd /var/www/html && \
      rm index.html; \
      cp wp-config-sample.php wp-config.php && \
      sed -i 's/database_name_here/wordpress_db/g' wp-config.php && \
      sed -i 's/username_here/wp_user/g' wp-config.php && \
      sed -i 's/password_here/password/g' wp-config.php && \
      rm -rf /tmp/wordpress /tmp/latest.tar.gz && \
      a2enmod php7.4
      systemctl restart apache2 --quiet" &>/dev/null
  else
    echo "wordpress is al geinstalleerd op server $server"
  fi

  # Check if webserver is reachable
  if nc -zv $server 80 &>/dev/null; then
    ((++counter))
  fi

done

unsucessfulInstalls=$(( $(wc -l < "$1") - $counter ))
echo "Op $counter servers is mysql & apache2 succesvol gestart"
echo "Op $unsucessfulInstalls servers is het niet gelukt om apache2 en mysql te starten"

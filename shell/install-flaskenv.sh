#!/bin/bash
# Script made by Romin Kleeman (531630)

###
#   Make sure this script is used on a server that has access via public key to the frontend and backend server
###


# Check whether script is run as root
# Comparing current run user with 0 since it's always the UID of root (root heeft de public key configuratie)
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

# Check whether there's atleast 1 given argument with script, else exit
if [ -z $1 ]; then
  echo -e "SYNOPSIS:\n\t${0:2} <frontend ip's (in bestand)> <backend omgeving> <omgeving>"
  exit 22 # 22 is the exit code for invalid argument
elif ! [ -f $1 ]; then
  echo "Bestand $1 bestaat niet. Script afgebroken"
  exit 2; # Returns no such file or directory
fi

# Count line for next file check & dependencies for installer
flines=(`wc -l $1`)
services=( git )

# Check whether conf file actually contains lines and set lines in array
if ! [[ $flines > 0 ]]; then
  echo "$1 is an empty config file, exiting..."
  exit;
else
  frontends=(`cat $1`)
fi

if [ -z $2 ]; then
  echo "Geen backend meegegeven"
else
  omgeving=$2
fi

if [ -z $3 ]; then
 echo "Geen omgeving meegegeven"
else
  omgeving=$3
fi

# Check whether the frontends are reachable through ssh, else exit
for frontend in "${frontends[@]}"
do
  if ! nc -zv $frontend 22 &>/dev/null; then
    echo "Couldn't ssh to $frontend"
    exit 68 # exit code 68 used for "host doesn't exist"
  fi
done

if ! nc -zv $backend 22 &>/dev/null; then
  echo "Couldn't ssh to $backend"
  exit 68 # exit code 68 used for "host doesn't exist"
fi

echo "Installatie via frontend (flask websites) $1"
echo -e "Op de volgende frontends wordt flask met gunicorn geinstalleerd en gestart:"
for frontend in "${frontends[@]}"
do
  echo "$frontend"
done
echo -e "Op de volgende service wordt de backend met flask geinstalleerd\n${backend}"

# Installeer en configureer backend

## Install git for backend (if it's not installed)
for service in "${services[@]}"
do
    # Installatie dependencies
    if [[ $(ssh $backend dpkg-query -s $service 2>/dev/null | awk '/^Status:/ {print $NF}') != "installed" ]]; then
      echo "Installatie frontend $frontend"
      ssh $backend "apt install ${service} -y" &>/dev/null
    fi
done

# Counter for succesful backend install
bcounter=0

## Installeer poetry op backend
ssh $backend "sudo curl -sSL https://install.python-poetry.org | python3 - && \
  echo 'PATH=~/.local/bin:$PATH' >>~/.bashrc && \
  echo 'export PATH' >>~/.bashrc && \
  exec bash && \
  cd /opt/ && \
  git clone https://gitlab.com/[redacted].git && \
  cd 14/Backend && \
  git checkout $omgeving && \
  poetry install && \
  cat > /etc/systemd/system/backend-saxcoin.service << EOL
  [Unit]
  Description=Systemd service to start Saxcoin backend with poetry
  After=network.target

  [Service]
  User=root
  WorkingDirectory=/opt/14/Backend
  ExecStart=/root/.local/bin/poetry run gunicorn app:app --bind 0.0.0.0:5000 --reload
  Restart=always

  [Install]
  WantedBy=multi-user.target
  EOL && \

  systemctl daemon-reload && \
  systemctl enable --now backend-saxcoin.service
  "

if nc -zv $backend 5000 &>/dev/null; then
    ((++bcounter));
fi

# Counter for amount of successful frontend installs
fcounter=0

# Check for each frontend if services are already installed, else install them and config the frontend flask
for frontend in "${frontends[@]}"
do
  for service in "${services[@]}"
  do
    # Installatie dependencies
    if [[ $(ssh $frontend dpkg-query -s $service 2>/dev/null | awk '/^Status:/ {print $NF}') != "installed" ]]; then
      echo "Installatie frontend $frontend"
      ssh $frontend "apt install ${service} -y" &>/dev/null
    fi
  done

    # Installatie poetry en set PATH Env for poetry
    ssh $frontend "sudo curl -sSL https://install.python-poetry.org | python3 - && \
      echo 'PATH=~/.local/bin:$PATH' >>~/.bashrc && \
      echo 'export PATH' >>~/.bashrc && \
      exec bash && \
      cd /opt/ && \
      git clone https://gitlab.com/[redacted] && \
      cd 14/Frontend && \
      git checkout $omgeving && \
      poetry install && \
      cat > /etc/systemd/system/frontend-saxcoin.service << EOL
      [Unit]
      Description=Systemd service to start Saxcoin frontend with poetry
      After=network.target

      [Service]
      User=root
      WorkingDirectory=/opt/14/Frontend
      ExecStart=/root/.local/bin/poetry run gunicorn app:app --bind 0.0.0.0:8080 --reload
      ExecReload=/bin/kill -HUP \$MAINPID
      Environment="SAXCOIN_BACKEND=http://${backend}:5000"
      Restart=always

      [Install]
      WantedBy=multi-user.target
      EOL && \

      systemctl daemon-reload && \
      systemctl enable --now frontend-saxcoin.service
      "

    # Checks for apache install and reachability
    if nc -zv $frontend 8080 &>/dev/null; then
       ((++fcounter));
    fi
done

unsucessfulInstalls=$(( $(wc -l < "$1") - $fcounter ))

# Frontend info install
echo "Op $fcounter frontends is installatie succesvol"
echo "Op $unsucessfulInstalls frontends is de installatie niet succesvol"

# Backendinfo install
echo "Op $bcounter backend is installatie succesvol"
if [ $2 -gt $bcounter ]; then
    echo "Op $backend server is de installatie niet succesvol"
fi

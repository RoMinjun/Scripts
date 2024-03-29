#!/bin/bash

# check current installed version
version=$(vmware -v | awk '{ print $3 }')

# gets the newest version from vmware
check_version=$(https https://www.vmware.com/go/getworkstation-linux -h | grep -i Location | awk -F '[-/]' '{ print $11 }')

if [[ "$check_version" == "$version" ]]; then
  echo "Current vmware version is the newest version"
  exit
fi

# Checks whether vmware version has fixed kernel modules
kernel_modules_version=$(curl -s -o /dev/null -I -w "%{http_code}" -L https://github.com/mkubecek/vmware-host-modules/archive/workstation-${check_version}.tar.gz)

if [ "${kernel_modules_version}" = "200" ]; then
  echo "File exists, downloading.."
  cd /tmp
  echo "Installing VMware Workstation ${check_version}..."
  https -d "https://www.vmware.com/go/getworkstation-linux"

  echo "Installing VMware Workstation ${check_version} kernel modules..."
  https -d "https://github.com/mkubecek/vmware-host-modules/archive/workstation-${check_version}.tar.gz"
else
  echo "Kernel module for version ${check_version} doesn't exists yet.."
  exit
fi

# run bundle file as script
chmod 764 $(pwd)/VMware-Workstation-Full-${check_version}*

echo "Installing VMware-Workstation-Full-${check_version}..."
sudo $(pwd)/VMware-Workstation-Full-${check_version}*

# check current installed version
newer_version=$(vmware -v | awk '{ print $3 }')

# vers 1
echo "Placing kernel modules on source..."
tar -xzf workstation-${newer_version}.tar.gz
cd vmware-host-modules-workstation-${newer_version}
tar -cf vmmon.tar vmmon-only
tar -cf vmnet.tar vmnet-only
cp -v vmmon.tar vmnet.tar /usr/lib/vmware/modules/source/

echo "Install new kernel modules..."
vmware-modconfig --console --install-all

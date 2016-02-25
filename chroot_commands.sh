#!/bin/bash

# Written by: https://github.com/turkgrb
# Website: https://daulton.ca
# Purpose: To make the backup and restoration of Gentoo systems easier, uses gzip
# tars and can also handle GRUB installation too with the restoration process.
# Note: This is the commands the main script run within the chroot environment

env-update 
source /etc/profile 
export PS1="(chroot) $PS1" 
		
echo "Beginning to sync and emerge grub.."
sudo emerge-webrsync
sudo emerge sys-boot/grub:2
	
# Sometimes grub saves new config with .new extension
# so this is assuring that an existing config is removed
# and the new one is renamed after installation so it can
# be used properly		
echo "Installing grub to disk and making config.."
sudo grub2-install $1
sudo rm -rf /boot/grub/grub.cfg
sudo grub2-mkconfig -o /boot/grub/grub.cfg
sudo mv /boot/grub/grub.cfg.new /boot/grub/grub.cfg

echo "Cleaning up.."
sudo rm -rf chroot_commands.sh
		 
exit

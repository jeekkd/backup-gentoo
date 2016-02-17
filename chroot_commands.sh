#!/bin/bash

# Written by: https://github.com/turkgrb
# Website: https://daulton.ca
# These are the commands that will be ran in the chroot when the 
# system is restored using the primary backup_gentoo.sh script
# Note: This is the commands the main script run within the chroot environment

env-update 
source /etc/profile 
export PS1="(chroot) $PS1" 
		
echo "Beginning to sync and emerge grub.."
sudo emerge --sync
sudo emerge --ask sys-boot/grub:2
		
echo "Installing grub to disk and making config.."
sudo grub2-install $1
sudo grub2-mkconfig -o /boot/grub/grub.cfg

echo "Cleaning up.."
sudo rm -rf chroot_commands.sh
		 
exit

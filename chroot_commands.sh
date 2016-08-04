#!/usr/bin/env bash
# Written by: https://gitlab.com/u/huuteml
# Website: https://daulton.ca
# Note: This is the commands the main script run within the chroot environment

env-update && source /etc/profile && export PS1="(chroot) $PS1" 
		
echo "Beginning to sync and emerge grub.."
emerge-webrsync
emerge -q sys-boot/grub:2 sys-boot/os-prober
	
# Sometimes grub saves new config with .new extension so this is assuring that an existing config is removed
# and the new one is renamed after installation so it can be used properly		
echo "Installing grub to disk and making config.."
if [ -z "$1" ]; then
	grub2-install --target=x86_64-efi
else
	grub2-install "$1"
fi

rm -f /boot/grub/grub.cfg

grub2-mkconfig -o /boot/grub/grub.cfg
if [ $? -eq 0 ]; then
	if [ -f /boot/grub/grub.cfg.new ]; then
		mv /boot/grub/grub.cfg.new /boot/grub/grub.cfg
	fi 
fi
		 
exit

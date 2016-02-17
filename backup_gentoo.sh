#!/bin/bash

# Written by: https://github.com/turkgrb
# Website: https://daulton.ca
# Purpose: To make the backup and restoration of Gentoo systems easier, uses bzipped
# tars and can also handle GRUB installation too.
# WARNING: BOOT TO SYSTEMRECSUECD TO USE

###### BACKUP SECTION ######

# Backup storeage location, Ex: /dev/sdb2
# Backup will be stored in root of the partition
backup_target=
# Gentoos root location, ex: /dev/sda1
root_backup_target=
# Gentoos boot location, ex: /dev/sda2
boot_backup_target=
# Gentoos home location, ex: /dev/sda3
home_backup_target=
# The name for the backup folder that will be made
backup_folder=gentoo_backups
#
###### RESTORE SECTION ######
#
# Disk to install grub2 to, Ex: /dev/sda
grub_disk=
# The target drive for the root restoration, ex: /dev/sda1
root_restore_target=
# The target drive for the boot restoration, ex: /dev/sda2
boot_restore_target=
# The target drive for the home restoration, ex: /dev/sda3
home_restore_target=
#
# The following variables don't NEED to be adjusted
#
# Todays date, used in the file name when creating the backup tar
today_date=$(date +%b_%d_%Y)
# File name and path for the backup tar
backup_tar_name="gentoo_backup_$today_date.tar.bz2"
###############################

# Credits to original author for this function as described below:	
# From: davejamesmiller/ask.sh
# What: Bash: General-purpose Yes/No prompt function ("ask") 
# URL: https://gist.github.com/davejamesmiller/1965569

ask() {
 
    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question - use /dev/tty in case stdin is redirected from somewhere else
        read -p "$1 [$prompt] " REPLY </dev/tty

        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi

        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

# get_script_dir()
# Gets the directory the script is being ran from
get_script_dir() {
	script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
}

# Leave here to get scripts running location before any directory changes occur
get_script_dir

# check_mount()
# Gets if /mnt/gentoo and /mnt/backup are already mounted, and if so they get umounted.
# This is to assure that if the mounts were previously used that the correct partition is
# mounted to it
check_mount() {

if mount | grep $backup_target || $root_backup_target || $root_restore_target > /dev/null; then

	echo "Directories found to be mounted, now unmounting so correct directory is now mounted..."
    umount -f /mnt/backup
    umount -f /mnt/gentoo
fi
	
}

while [ true ]
do

echo
	echo "------------------------------"
	echo "Gentoo backup script"
	echo "Note: Remember to set the variables in the file and double check them!"
	echo "------------------------------"
	echo
	echo "A. Backup system"
	echo "B. Restore ststem"
	echo "C. Exit script"
	echo
	echo -n "Enter a selection: "
	read option
	
case "$option" in
		
[Aa])

	echo "This will completely back up your system into a bzipped tar, and store it"
	echo "at /mnt/backup/$backup_folder on $backup_target"
	ask

	echo "Making directories.."
	mkdir -v /mnt/gentoo 
	mkdir -v /mnt/backup
	mkdir -v /mnt/backup/$backup_folder
	
	check_mount
	
	echo "Mounting directories.."
	mount $root_backup_target /mnt/gentoo 
	mount $boot_backup_target /mnt/gentoo/boot
	mount $home_backup_target /mnt/gentoo/home
	mount $backup_target /mnt/backup 

	echo "Creating backup tar.. may take a while, please wait"
	cd /mnt/gentoo
	tar --xattrs -cvpf /mnt/backup/$backup_folder/$backup_tar_name --directory=/mnt/gentoo --exclude=proc --exclude=sys --exclude=dev/pts . 
	if [ $? -eq 0 ]; then
		isExist=$(ls /mnt/backup/$backup_folder | grep "$backup_tar_name")
		
		if [ -z "$isExist" ]; then
			echo "Error: Backup did not complete successfully. Does not exist"
		else
			echo "Backup exists.. now umounting file systems"
			umount -vf /mnt/gentoo/boot /mnt/gentoo/home /mnt/gentoo /mnt/backup 
		fi
		
	fi
	echo "Complete.."

;;
[Bb])

	echo "This will restore your system onto $root_restore_target and install grub onto $grub_disk."
	echo "Any data left on the partition will be overwritten by the restoration. Continue? Y or N."
	ask
	
	check_mount
	
	mkdir -v /mnt/gentoo/boot
	mkdir -v /mnt/gentoo/home
	
	echo "Mounting listed drives to correct mount points.."
	mount -v $root_restore_target /mnt/gentoo 
	mount -v $home_restore_target /mnt/gentoo/home
	mount -v $boot_restore_target /mnt/gentoo/boot
	mount -v $backup_target /mnt/backup 
	
	echo "Making directories.."
	mkdir -v /mnt/gentoo
	mkdir -v /mnt/gentoo/dev
	mkdir -v /mnt/gentoo/proc
	mkdir -v /mnt/gentoo/sys
	mkdir -v /mnt/gentoo/tmp
	mkdir -v /mnt/backup
	
	echo "Mounting filesystems.."
	mount -o rbind /dev /mnt/gentoo/dev 
	mount -t proc none /mnt/gentoo/proc 
	mount -o bind /sys /mnt/gentoo/sys 
	mount -o bind /tmp /mnt/gentoo/tmp 
	
	echo "Changing directory to /mnt/backup"
	cd /mnt/backup 
	if [ $? -gt 0 ]; then
		echo "Error: Could not change directory to /mnt/backup"
	else
		echo "Creating backup directory"
		mkdir $backup_folder
	fi
	
	cd $backup_folder
	if [ $? -gt 0 ]; then
		echo "Error: Could not change directory to $gentoo_backups - creating..."
		mkdir $backup_folder
		cd $backup_folder
	fi
	
	echo "---------------------------"
	echo "Type the number to the backup you wish to restore."
	echo "---------------------------"
	echo
	
	ls | cat -n
	read which_file
	selected_file=$(ls | sed -n $which_file\p)
	
	echo "Restoriong backup tar.."
	tar --xattrs -xvpf $selected_file -C /mnt/gentoo/

	if [ $? -eq 0 ]; then
		
		echo "Copying resolv.conf over"
		cp /etc/resolv.conf /mnt/gentoo/etc
		
		echo "Calling script to run commands in the chroot"
		cp -v $script_dir/chroot_commands.sh /mnt/gentoo
		chroot /mnt/gentoo ./chroot_commands.sh $grub_disk
		
		if [ $? -eq 0 ]; then
			echo "Unmounting drives now.."
			umount -vf /mnt/gentoo/boot /mnt/gentoo/home /mnt/gentoo /mnt/backup 
		fi
	fi
	
	echo "Complete.."
;;
[Cc])
	exit
;;
*)
	echo "Enter a valid selection from the menu."
;;	
esac 	
done

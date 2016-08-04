#!/usr/bin/env bash
# Written by:  https://gitlab.com/u/huuteml
# Website: https://daulton.ca
# Purpose: To make the backup and restoration of Gentoo systems easier, uses bzipped
# tars and can also handle GRUB installation too.
# WARNING: BOOT TO SYSTEMRECSUECD TO USE

###### BACKUP SECTION ######

# Backup storeage location, Ex: /dev/sdb2
# Backup will be stored in root of the partition
backup_target=/dev/sdb2

# Gentoos root location, ex: /dev/sda1
gentoo_backup_target=/dev/sdb1

# The name for the backup folder that will be made
backup_folder=gentoo_backups

###### RESTORE SECTION ######
# IF YOUR SYSTEM IS EFI AND WANT IT TO INSTALL GRUB AS SUCH DO NOT SET THIS VARIABLE. 
# The disk to install grub2 to, Ex: /dev/sda
grub_disk=/dev/sdb

# The target drive for the restoration, ex: /dev/sda1
gentoo_restore_target=/dev/sdb1

######## MISC SECTION ########
# Todays date, used in the file name when creating the backup tar
today_date=$(date +%b_%d_%Y)

# File name and path for the backup tar
backup_tar_name="gentoo_backup_$today_date.tar.gz"
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
        read -pr "$1 [$prompt] " REPLY </dev/tty

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
	if mount | grep $backup_target || $gentoo_backup_target || $gentoo_restore_target > /dev/null; then
		echo "Directories found to be mounted, now unmounting so correct directory is now mounted..."
		umount /mnt/backup
		umount /mnt/gentoo
	fi	
}

while true ; do
	echo
	echo "------------------------------"
	echo "Gentoo backup script"
	echo "Written by:  https://gitlab.com/u/huuteml"
	echo "Note: Remember to set the variables in the file and double check them!"
	echo "------------------------------"
	echo
	echo "A. Backup system"
	echo "B. Restore ststem"
	echo "C. Exit script"
	echo
	echo -n "Enter a selection: "
	read -r option
		
	case "$option" in
			
	[Aa])

		echo "This will completely back up your system into a bzipped tar, and store it"
		echo "at /mnt/backup/$backup_folder on $backup_target"
		ask "$@"

		echo "Making directories.."
		mkdir -v /mnt/gentoo 
		mkdir -v /mnt/backup
		mkdir -v /mnt/backup/$backup_folder
		
		check_mount
		
		echo "Mounting directories.."
		mount "$gentoo_backup_target" /mnt/gentoo 
		mount "$backup_target" /mnt/backup 

		echo "Creating backup tar.. may take a while, please wait"
		cd /mnt/gentoo || exit
		tar --xattrs -czpvf /mnt/backup/"$backup_folder"/"$backup_tar_name" --directory=/mnt/gentoo --exclude=proc --exclude=sys --exclude=dev/pts . 
		if [ $? -eq 0 ]; then
			isExist=$(ls /mnt/backup/"$backup_folder" | grep "$backup_tar_name")			
			if [ -z "$isExist" ]; then
				echo "Error: Backup did not complete successfully. Does not exist"
			else
				echo "Backup exists.. now umounting file systems"
				umount -v /mnt/gentoo /mnt/backup 
			fi			
		fi
		echo "Complete.."

	;;
	[Bb])
	
		echo "This will restore your system onto $gentoo_restore_target and install grub onto $grub_disk."
		echo "Any data left on the partition will be overwritten by the restoration"
		ask "$@"
		
		check_mount
		
		echo "Formatting partition.."	
		mkfs.ext4 "$gentoo_restore_target"
		
		echo "Mounting listed drives to correct mount points.."
		mount -v "$gentoo_restore_target" /mnt/gentoo 
		mount -v "$backup_target" /mnt/backup 
		
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
		cd /mnt/backup  || exit
		if [ $? -gt 0 ]; then
			echo "Error: Could not change directory to /mnt/backup"
		else
			echo "Creating backup directory"
			mkdir "$backup_folder"
		fi
		
		cd $backup_folder || exit
		if [ $? -gt 0 ]; then
			echo "Error: Could not change directory to $gentoo_backups - creating..."
			mkdir "$backup_folder"
			cd "$backup_folder"
		fi
		
		echo "---------------------------"
		echo "Type the number to the backup you wish to restore"
		echo "---------------------------"
		echo
		
		ls | cat -n
		read -r which_file
		selected_file=$(ls | sed -n "$which_file"\p)
		
		echo "Restoriong backup tar.."
		tar --xattrs -xpf "$selected_file" -C /mnt/gentoo/

		if [ $? -eq 0 ]; then			
			echo "Copying resolv.conf over"
			cp /etc/resolv.conf /mnt/gentoo/etc
						
			echo "Calling script to run commands in the chroot"
			cp -v "$script_dir"/chroot_commands.sh /mnt/gentoo
			chroot /mnt/gentoo ./chroot_commands.sh "$grub_disk"
			
			umount -v /mnt/gentoo /mnt/backup 
		fi
		
		echo "Complete.."
	;;
	[Cc])
		exit
	;;
	*)
		echo "Enter a valid selection from the menu - options include A to C"
	;;	
	esac 	
done

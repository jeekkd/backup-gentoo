Purpose
=====

The purpose of this script is to make the backup and restoration
of Gentoo systems easier. This is achieved by having a convenient
menu, both backup and restore capable, and minimal interaction
aside from setting a few variables before being ran.

This script could be adapted to be used on other distributions if
one were to edit the chroot_commands.sh script to reflect the
commands that need to be ran for your distribution to install 
and configure GRUB. That would fairly easy, so if you are not
using Gentoo but need a script like this give it a go.

How to use
====

It is heavily advised to use a live cd system such as SystemRescueCD
to launch this script from, it is not wise to attempt to do a full
system backup on a live system at least using tar backups.

Do the following -

sudo chmod 770 backup_gentoo.sh chroot_commands.sh

This will make the script readable, writable, and executable to 
root and your user. Next, open the script in your text editor of 
choice.

geany backup_gentoo.sh

You need to edit the variables in the highlighted variables section 
near the top. To find the information required use a ultility such 
as gparted, SystemRescueCD has this by default.

Next, you will want to make sure you've saved and then launch the 
script by doing the following;

sudo bash backup_gentoo.sh


> **Note:**
> 
> - Unless your user is in the passwordless wheel group you will need to enter 
your password when prompted when you are doing a system restore.

#!/bin/bash

###Colors
black='\e[0;30m'
dgray='\e[1;30m'
lgray='\e[0;37m'
blue='\e[0;34m'
lblue='\e[1;34m'
green='\e[0;32m'
lgreen='\e[1;32m'
cyan='\e[0;36m'
lcyan='\e[1;36m'
red='\e[0;31m'
lred='\e[1;31m'
purple='\e[0;35m'
lpurple='\e[1;35m'
brown='\e[0;33m'
yellow='\e[1;33m'
white='\e[1;37m'
nocolor='\e[0m'

###Input domain
DOMAIN=$(whiptail --inputbox "Check file/folder permissions for which domain? (No spaces)" 8 78 domain.com --title "Input Domain" 3>&1 1>&2 2>&3)
exitstatus=$?
[ $exitstatus = 0 ]

###Define user
USER=$(/scripts/whoowns $DOMAIN)

###Exit if user doesn't exist
if id -u "$USER" >/dev/null 2>&1; then
echo ""
else 
echo -e ""$red"Error: This domain does not exist on the server!$nocolor"
exit
fi

cd /home/$USER

###Find permission backups
if test -f /home/$USER/pre-perm-fixer.$USER; then

###Ask to restore permissions
whiptail --title "Restore Permissions" --yesno "Would you like to restore permissions for $USER" 8 78 then
  cd /home/$USER
  setfacl --restore=pre-perm-fixer.$USER 
  echo -e "\n"$green"Permissions restored!$nocolor\n"
  exit 1
else 
  echo ""
fi

echo -e "$lblue*******************************************************************$nocolor"
echo -e "\n"$green"You chose the following domain:$nocolor" $yellow$DOMAIN$nocolor

###PHP Handler
echo -e "\n$lblue*****$nocolor "$green"PHP Handler$nocolor $lblue*****$nocolor\n"
/usr/local/cpanel/bin/rebuild_phpconf --current

###777 Folders
echo -e "\n$lblue*****$nocolor $green"$USER"'s 777 Folders$nocolor $lblue*****$nocolor\n"
find /home/$USER/ -perm 0777 -type d -print

###Backup current permissions
{
    for ((i = 0 ; i <= 100 ; i+=5)); do
        getfacl -R . > pre-perm-fixer.$USER
        echo $i
    done
} | whiptail --gauge "Backing up current permissions for $USER..." 6 50 0

echo -e "\n"$green"Backup can be found at$nocolor$yellow /home/$USER/pre-perm-fixer.$USER $nocolor\n"
echo -e "$lblue*******************************************************************$nocolor"

###Ask to correct permissions
if (whiptail --title "Correct Permissions" --yesno "Would you like to correct permissions for $USER" 8 78) then
    find /home/$USER -type d -print0 | xargs -0 chmod 755
    find /home/$USER -type f -print0 | xargs -0 chmod 644
else
    echo ""
fi

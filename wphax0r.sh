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

###Credits
echo -e "\n$lblue=======$nocolor$green WP Hax (CentOS/cPanel)$nocolor by "$yellow"fsanzica $nocolor$lblue=======$nolcolor"

###Find other WP installs
#for file in $(find /home*/*/ -name wp-config.php);do echo $file|awk -F "/" '{$NF=""}1'|tr " " "/" ;done

###Input domain
DOMAIN=$(whiptail --inputbox "Which WordPress domain do you suspect is hacked? (No spaces)" 8 78 domain.com --title "Input WordPress Domain" 3>&1 1>&2 2>&3)
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

###Exit if site is not WordPress
if [ ! -f /home/$USER/public_html/wp-config.php ]; then
echo -e ""$red"Error: This domain does not have WordPress installed in /public_html!$nocolor"
exit
else
echo -n ""
fi

###WP version
echo -e "\n$lblue*****$nocolor "$green"WordPress Version$nocolor $lblue*****$nocolor\n"
WPVERSION=`grep "wp_version =" /home/$USER/public_html/wp-includes/version.php | awk '{print $3}' | sed 's/;//'|sed "s/'//g"`

###Latest WP version
LATEST=`curl 2>/dev/null https://wordpress.org/download/ | grep "(Version" | awk '{print $9}' | sed 's/)//'`

###Version check
if [ $WPVERSION != $LATEST ]
then
echo -e ""$red"You Should Upgrade WordPress to the Latest Version ($LATEST)$nocolor"
else
echo -e ""$yellow"You Have the Latest Version of WordPress ($LATEST)$nocolor"
fi

###WordPress DB
echo -e "\n$lblue*****$nocolor "$green"WordPress Database$nocolor $lblue*****$nocolor\n"
grep "define('DB_NAME'" /home/$USER/public_html/wp-config.php | cut -d "'" -f4


###PHP handler
echo -e "\n$lblue*****$nocolor "$green"PHP Handler$nocolor $lblue*****$nocolor\n"
/usr/local/cpanel/bin/rebuild_phpconf --current

###.htaccess redirects
echo -e "\n$lblue*****$nocolor "$green".htaccess Redirects$nocolor $lblue*****$nocolor\n"
cat /home/$USER/public_html/.htaccess | grep -i rewrite

###Recently modified /uploads
cd /home/$USER/public_html/wp-content/uploads
echo -e "\n$lblue*****$nocolor "$green"Recently Modified Files in /uploads$nocolor $lblue*****$nocolor\n"
ls -lartch

### Potentially malicious /uploads
echo -e "\n$lblue*****$nocolor "$green"Potentially Malicious Files in /uploads$nocolor $lblue*****$nocolor\n"
find ./ -type f -name '*.php'
cd ..

###Recently modified /wp-content
echo -e "\n$lblue*****$nocolor "$green"Recently Modified Files in /wp-content$nocolor $lblue*****$nocolor\n"
ls -lartch
cd /home/$USER/public_html/wp-includes

###First line length in wp-config
echo -e "\n$lblue*****$nocolor "$green"Length of First Line in wp-config$nocolor $lblue*****$nocolor\n"
head -1 /home/$USER/public_html/wp-config.php | wc -c

###Last 10 FTP uploads from user
echo -e "\n$lblue*****$nocolor "$green"Last 10 FTP Uploads for $USER$nocolor $lblue*****$nocolor\n"
tail -1000 /var/log/messages | grep $USER | grep -i upload | tail

###Last 10 in SSH Logs from user
echo -e "\n$lblue*****$nocolor "$green"Last 10 in SSH Logs for $USER$nocolor $lblue*****$nocolor\n"
tail -1000 /var/log/secure | grep $USER | tail 

###Last 10 cPanel File Manager uploads from user
echo -e "\n$lblue*****$nocolor "$green"Last 10 cPanel File Manager Uploads From $USER$nocolor $lblue*****$nocolor\n"
tail -1000 /usr/local/cpanel/logs/access_log | grep -i $USER | grep -i upload | tail

###Last 10 from domlog
echo -e "\n$lblue*****$nocolor "$green"Last 10 from domlog$nocolor $lblue*****$nocolor\n"
grep "=http" /usr/local/apache/domlogs/$DOMAIN | grep "HTTP/1.1\" 200" |egrep -v "google|translate|yahoo" | tail
echo ""

###Ask for maldet
if(whiptail --title "Malware Scan" --yesno "Would you like to run a maldet for $USER?" 8 78) then
/scripts/update_local_rpm_versions --edit target_settings.clamav installed
/scripts/check_cpanel_rpms --fix --targets=clamav 
ln -s /usr/local/cpanel/3rdparty/bin/clamscan /usr/bin/clamscan
ln -s /usr/local/cpanel/3rdparty/bin/freshclam /usr/bin/freshclam
cd /usr/local/cpanel/3rdparty/perl/514/bin/ ; /bin/cp -avu sa-check_spamd spamassassin spamc spamd sa-awl  sa-compile sa-learn sa-update /usr/bin/
/usr/bin/freshclam
pushd /usr/local/src/
rm -vrf maldetect-*
wget http://www.rfxn.com/downloads/maldetect-current.tar.gz
tar -xzf maldetect-current.tar.gz
cd maldetect-*
sh ./install.sh
maldet --update-ver
maldet --update
line=$(grep -n "/usr/local/maldetect/maldet -b -r /home?/?/public_html 2" /etc/cron.daily/maldet | cut -f1 -d:);  if [[ $line != [0-9]* ]]; then echo "The search string was not found, please let escalations know of this."; else sed -i "$line s/^/#/" /etc/cron.daily/maldet && line=$((line+1)) && sed -i "$(echo $line)i\echo " /etc/cron.daily/maldet; fi
maldet  -b -a /home/$USER/public_html
tail -f /usr/local/maldetect/event_log
else
echo ""
fi

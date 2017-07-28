#!/bin/bash

###WordPress
echo -e "\n===\e[32m WordPress Versions\033[0m ===\n";
for i in $(cat /usr/local/apache/conf/httpd.conf | grep DocumentRoot | awk '{print $2}'| sort | uniq | sort);do if [ `ls -A $i | grep wp-settings.php` ]; then echo $i `grep Vers $i/readme.html | awk '{print $4}'`; fi; done;

###Drupal
echo -e "\n===\e[32m Drupal Versions\033[0m ===\n";
for i in $(cat /usr/local/apache/conf/httpd.conf | grep DocumentRoot | awk '{print $2}'| sort | uniq | sort);do if [ `ls -A $i | grep CHANGELOG.txt` ]; then echo $i `grep "Drupal" $i/CHANGELOG.txt | head -1 |sed 's/,//'|awk '{print $2}'`; fi; done;

###Joomla
echo -e "\n===\e[32m Joomla Versions\033[0m ===\n";
for i in $(cat /usr/local/apache/conf/httpd.conf | grep DocumentRoot | awk '{print $2}'| sort | uniq | sort);do if [ `ls -A $i | grep CHANGELOG.php` ]; then echo $i `grep "Stable Release" $i/CHANGELOG.php | head -1 | awk '{print $2}'`; fi; done;

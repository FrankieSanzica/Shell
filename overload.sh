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

###Current dubya
echo -e "\n$lblue*****$nocolor$green Dubya$nocolor $lblue*****$nocolor\n"
w |tee /tmp/delete_w

###Save current free memory
free -m > /tmp/delete_free

####Save current ps fauxww
ps fauxww > /tmp/delete_ps

###Save current netstat -tn
netstat -tn > /tmp/delete_netstat

###Save current MySQL proc
mysqladmin proc > /tmp/delete_mysqladmin

###Save current WHM status
timeout 10s /usr/bin/lynx -dump -width 500 http://127.0.0.1/whm-server-status > /tmp/delete_lynx

###CPU/MEM Usage by Process
echo -e "\n$lblue*****$nocolor$green Current CPU/MEM Usage by Process$nocolor $lblue*****$nocolor\n"
date
echo ""
#HTTP
ps aux |awk -v C=$(grep -c proc /proc/cpuinfo) '/\/usr\/local\/apache\/bin\/httpd/ {a+=$3}END{print "HTTP CPU%: " a/C}'
ps aux |awk -v C=$(grep -c proc /proc/cpuinfo) '/\/usr\/local\/apache\/bin\/httpd/ {a+=$4}END{print "HTTP MEM%: " a/C}'
#PHP
ps aux |awk -v C=$(grep -c proc /proc/cpuinfo) '/\/usr\/bin\/php/ {a+=$3}END{print "PHP CPU%: " a/C}'
ps aux |awk -v C=$(grep -c proc /proc/cpuinfo) '/\/usr\/bin\/php/ {a+=$4}END{print "PHP MEM%: " a/C}'
#MYSQL
ps aux |awk -v C=$(grep -c proc /proc/cpuinfo) '/\/usr\/sbin\/mysqld/ {a+=$3}END{print "MySQL CPU%: " a/C}'
ps aux |awk -v C=$(grep -c proc /proc/cpuinfo) '/\/usr\/sbin\/mysqld/ {a+=$4}END{print "MySQL MEM%: " a/C}'

###Logged
echo -e "\n"$yellow"All Information Logged$nocolor"

CORES=$(grep processor /proc/cpuinfo | wc -l |bc -l)
LOAD=$(uptime | awk '{print $10}' | sed 's/,//'| cut -f1 -d"."| bc -l)

###Ask to killall
if [ "$LOAD" -ge "$CORES" ] && (whiptail --title "Load is above CPU cores" --yesno "Would you like to killall -9 httpd php?" 8 78)
then
    killall -9 httpd php
else 
    echo ""
fi

###Basic Info
echo -e "$lblue*****$nocolor$green Basic Info$nocolor $lblue*****$nocolor\n"
echo -e "CPUs:" $(grep -c proc /proc/cpuinfo)
free -m | awk '/Mem/ {print $1,$2}'
echo ""
df -h

###Mem Use
echo -e "\n$lblue*****$nocolor$green Use During Load$nocolor $lblue*****$nocolor\n" 
egrep -o '(load.*)' /tmp/delete_w 
echo Free RAM: $(grep '+' /tmp/delete_free |awk '{print $3}') / $(grep 'M' /tmp/delete_free |awk '{print $2}')
awk ' /S/ {print "Free SWAP:",$4,"/",$2"\n" }' /tmp/delete_free

###User Info
echo -e "\n$lblue*****$nocolor$green User Information$nocolor $lblue*****$nocolor\n"
grep -v "0.0  0.0" /tmp/delete_ps | awk '{print $1}' |grep -v USER |sort |uniq >> ps_user
for i in `cat ps_user`
do grep $i /tmp/delete_ps |awk '{SUM +=$3}END{print SUM}'
done >> ps_cpu
for i in `cat ps_user`
do grep $i /tmp/delete_ps |awk '{SUM +=$4}END{print SUM}'
done >> ps_mem
paste ps_user ps_cpu ps_mem > ps_final_form
(echo -n 'User CPU Memory';echo;cat ps_final_form)> ps_final_form.new; mv -f ps_final_form{.new,} 
cat ps_final_form|column -t; rm -f ps_cpu ps_final_form ps_mem ps_user

###Service Breakdown
echo -e "\n$lblue*****$nocolor$green Service Breakdown$nocolor $lblue*****$nocolor"
#Apache
echo -e "\n"$yellow"* Apache *$nocolor\n"
echo -e ""$blue"Ports: $nocolor"
netstat -lpn |awk '/0\.0.*http/ {print $4}' | cut -d: -f2 | tr '\n' ' '
echo -e "\n"$blue"Configurations: $nocolor"
egrep '(Max[CRK]|ServerL|Keep)' /usr/local/apache/conf/httpd.conf || 
echo UNSET
echo -e ""$blue"Processes: $nocolor"
grep -c httpd /tmp/delete_ps
echo -e ""$blue"MaxClients Reached Today: $nocolor"
grep "$(date +%a' '%b' '%d)".*MaxC /usr/local/apache/logs/error_log |tail
echo -e ""$blue"Port 80:$nocolor" 
awk '/:80 / { print $5}' /tmp/delete_netstat | cut -d ':' -f1 | sort | uniq -c | sort -nr | head 
#Domains
echo -e "\n"$yellow"* Domains *$nocolor\n"
awk ' /:80 / {print $12}' /tmp/delete_lynx|cut -d':' -f1 |sort |uniq -c |sort -nr |head
echo -e ""$blue"Port 443:$nocolor"
awk '/:443/ {print $5}' /tmp/delete_netstat | cut -d ':' -f1 | sort | uniq -c | sort -nr | head
awk ' /:443 / {print $12}' /tmp/delete_lynx |cut -d':' -f1 |sort |uniq -c |sort -nr |head
#PHP
echo -e "\n"$yellow"* PHP *$nocolor\n"
echo -e ""$blue"Configurations: $nocolor"
egrep '(memory_|execution_)' /usr/local/lib/php.ini | cut -d';' -f1
echo -e ""$blue"Processes: $nocolor"
grep -c php /tmp/delete_ps
echo -e ""$blue"Active PHP: $nocolor"
egrep -o '(/usr/bin/php.*)' /tmp/delete_ps | awk '{print $2}' |sort |uniq -c |sort -nr |head
#MYSQL
echo -e "\n"$yellow"* MySQL *$nocolor\n"
$(netstat -lpn |grep mysql | grep 0.0 |awk '{print $4}' | cut -d':' -f2)
echo -e ""$blue"Configurations: $nocolor"
egrep '(max_c|query_|tmp_|innodb_|_time)' /etc/my.cnf || 
echo UNSET
echo -e ""$blue"MySQL Processes: $nocolor"
grep -c mysql /tmp/delete_ps
cat /tmp/delete_mysqladmin
echo -e ""$blue"Crashed DBs: $nocolor"
grep "$(date "+%y%m%d")" /var/lib/mysql/$(hostname).err|grep -i crashed|tail
#Exim
echo -e "\n"$yellow"* Exim *$nocolor\n"
echo -e ""$blue"Ports: $nocolor"
netstat -lpn |grep exim | grep 0.0 |awk '{print $4}' | cut -d':' -f2 | tr '\n' ' '
echo -e "\n"$blue"Processes: $nocolor"
grep -c exim /tmp/delete_ps
echo -e ""$blue"Queue: $nocolor\n$(exim -bpc)\\n"$blue"Port:$nocolor \n25"
awk '/:25 / {print $5}' /tmp/delete_netstat| cut -d ':' -f1 | sort | uniq -c | sort -nr | head

exit

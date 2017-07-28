#!/bin/bash

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

SERVERCHK=$( df -P /home |tail -1 | awk '{print $NF}')
if [[ $SERVERCHK == / ]]
then
SERVERTYPE="VPS"
else
SERVERTYPE="DEDI"
fi

SERVERCHK=$( df -P /home |tail -1 | awk '{print $NF}')
if [[ $SERVERCHK == / ]]
then
SERVERTYPE="VPS"
else
SERVERTYPE="DEDI"
fi


if [[ $SERVERTYPE == 'VPS' ]]
then
echo -e "\n$lblue===$nocolor$green Suggested Apache Baseline$nocolor $lblue===$nocolor\n"
echo -e "KeepAlive "$blue"On$nocolor"
echo -e "Timeout "$blue"100$nocolor"
echo -e "MaxKeepAliveRequests "$blue"100$nocolor"
echo -e "KeepAliveTimeout "$blue"5$nocolor"
echo -e "MinSpareServers "$blue"5$nocolor"
echo -e "MaxSpareServers "$blue"10$nocolor"
echo -e "StartServers "$blue"5$nocolor"
echo -e "MaxClients "$blue"150$nocolor"
echo -e "MaxRequestsPerChild "$blue"300$nocolor"
echo ""
else
echo -e "\n$lblue===$nocolor$green Suggested Apache Baseline$nocolor $lblue===$nocolor\n"
echo -e "KeepAlive "$blue"On$nocolor"
echo -e "Timeout "$blue"150$nocolor"
echo -e "MaxKeepAliveRequests "$blue"150$nocolor"
echo -e "KeepAliveTimeout "$blue"5$nocolor"
echo -e "MinSpareServers "$blue"10$nocolor"
echo -e "MaxSpareServers "$blue"20$nocolor"
echo -e "StartServers "$blue"10$nocolor"
echo -e "MaxClients "$blue"250$nocolor"
echo -e "MaxRequestsPerChild "$blue"500$nocolor"
echo ""
fi

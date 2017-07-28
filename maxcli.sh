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

###Global Buffers Variables
innodb_buffer_pool_size=$(mysql -Bse "SHOW GLOBAL VARIABLES"|grep innodb_buffer_pool_size| awk '{print $2}')

innodb_additional_mem_pool_size=$(mysql -Bse "SHOW GLOBAL VARIABLES"  | grep innodb_additional_mem_pool_size| awk '{print $2}')

innodb_log_buffer_size=$(mysql -Bse "SHOW GLOBAL VARIABLES"  | grep innodb_log_buffer_size| awk '{print $2}')

key_buffer_size=$(mysql -Bse "SHOW GLOBAL VARIABLES"  | grep key_buffer_size| awk '{print $2}')

query_cache_size=$(mysql -Bse "SHOW GLOBAL VARIABLES"  | grep query_cache_size| awk '{print $2}')

###Global Buffers
global_buffers=$(echo "$innodb_buffer_pool_size+$innodb_additional_mem_pool_size+$innodb_log_buffer_size+$key_buffer_size+$query_cache_size" | bc -l)

###Per Thread Max Buffers Variables
read_buffer_size=$(mysql -Bse "SHOW GLOBAL VARIABLES"  |grep read_buffer_size| awk '{print $2}')

read_rnd_buffer_size=$(mysql -Bse "SHOW GLOBAL VARIABLES"  | grep read_rnd_buffer_size| awk '{print $2}')

sort_buffer_size=$(mysql -Bse "SHOW GLOBAL VARIABLES"  | grep sort_buffer_size | grep -v myisam| grep -v innodb|awk '{print $2}')

thread_stack=$(mysql -Bse "SHOW GLOBAL VARIABLES"  | grep thread_stack| awk '{print $2}')

join_buffer_size=$(mysql -Bse "SHOW GLOBAL VARIABLES"  | grep join_buffer_size| awk '{print $2}')

binlog_cache_size=$(mysql -Bse "SHOW GLOBAL VARIABLES"  | grep binlog_cache_size|grep -v max | grep -v "p"| awk '{print $2}')

max_used_connections=$(mysql -Bse "show global status like '%Max_used%'" | awk '{print $2}')

###Per Thread Max Buffers
per_thread_max_buffers=$(echo "($read_buffer_size+$read_rnd_buffer_size+$sort_buffer_size+$thread_stack+$join_buffer_size+$binlog_cache_size)*$max_used_connections" | bc -l)

###Max Memory Ever Allocated
max_memory=$(echo "$global_buffers+$per_thread_max_buffers" | bc -l)

###Math Variables
m1=$(echo "$max_memory/1000000"|bc -l | cut -d '.' -f1);
m2=`free -m | grep 'Mem:' | awk '{print $2}'`;
m3=`cat /usr/local/lib/php.ini | grep memory_limit |grep -v ';memory_limit'|grep -v 'suhosin.memory_limit'|awk '{print $3}'| sed 's/M//'`;
echo -e "$lblue===$nocolor $green Suggested Apache Max Clients (To Prevent OOM) $nocolor$lblue===$nocolor";
echo -e "\n[Total Memory $yellow$m2(M)$nocolor - Max MySQL Memory $yellow$m1(M)$nocolor / PHP Memory Limit $yellow$m3(M)$nocolor = \n";
m4=`echo "$m2 - $m1" | bc`
m5=`echo $m4 / $m3| bc`
m6=`cat /usr/local/apache/conf/httpd.conf | egrep 'MaxRequestWorkers|MaxClients'|awk '{print $2}'`
echo -e ""$red"Current Max Clients:$nocolor $m6";
echo -e ""$blue"Suggested Max Clients:$nocolor $m5";
echo -e "\n"$red"WARNING! This is theoretical based on the above equation to prevent OOM.  Use caution and your brain when setting this.  If the suggested setting is too low, lower memory in PHP memory_limit or MySQL memory buffers.  Also, remember to change the server_limit setting as well. $nocolor";

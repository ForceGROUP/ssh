#!/bin/bash
u_dir="/etc/SSHPlus/userDir"
#
[[ ! -d "$u_dir" ]] && mkdir $u_dir
function_dropb () {  
port_dropbear=`ps aux | grep dropbear | awk NR==1 | awk '{print $17;}'`
[[ $port_dropbear = "" ]] && return
log=/var/log/auth.log
loginsukses='Password auth succeeded'
echo ' '
pids=`ps ax |grep dropbear |grep  " $port_dropbear" |awk -F" " '{print $1}'`
for pid in $pids
do
    pidlogs=`grep $pid $log |grep "$loginsukses" |awk -F" " '{print $3}'`
    i=0
    for pidend in $pidlogs
    do
    let i=i+1
    done
    if [ $pidend ]; then
       login=`grep $pid $log |grep "$pidend" |grep "$loginsukses"`
       PID=$pid
       user=`echo $login |awk -F" " '{print $10}' | sed -r "s/'/ /g"`
       waktu=`echo $login |awk -F" " '{print $2"-"$1,$3}'`
       while [ ${#waktu} -lt 13 ]; do
       waktu=$waktu" "
       done
       while [ ${#user} -lt 16 ]; do
       user=$user" "
       done
       while [ ${#PID} -lt 8 ]; do
       PID=$PID" "
       done
     echo "$user $PID $waktu"
    fi
done
echo ""
return
}



fun_ovpn_onl () {
for userovpn in `cat /etc/passwd | grep ovpn | awk -F: '{print $1}'`; do
us=$(cat /etc/openvpn/openvpn-status.log | grep $userovpn | wc -l)
[[ "$us" != "0" ]] && echo "$userovpn"
done
}


function_killmultiloguin () {
(
for user in `awk -F : '$3 > 900 { print $1 }' /etc/passwd |grep -v "nobody" |grep -vi polkitd |grep -vi system-`; do
unset pid_limite && unset sshd_on && unset drop_on
sshd_on=$(ps -u $user|grep sshd|wc -l)
drop_on=$(function_dropb|grep "$user"|wc -l)
[[ -e $u_dir/$user ]] && pid_limite=$(cat $u_dir/$user | grep "limite:" | awk '{print $2}') || pid_limite="200"
[[ $pid_limite != +([0-9]) ]] && pid_limite="200""
#LIMITE DROPBEAR
   [[ "$drop_on" -gt "$pid_limite" ]] && {
           kill=$((${drop_on}-${pid_limite}))
           pids=$(function_dropb|grep "$user"|awk '{print $2}'|tail -n${kill})
           for pid in `echo $pids`; do
           kill $pid
           done
    }
#LIMITE OPENSSH
   [[ "$sshd_on" -gt "$pid_limite" ]] && {
           kill=$((${sshd_on}-${pid_limite}))
           pids=$(ps x|grep [[:space:]]$user[[:space:]]|grep -v grep|grep -v pts|awk '{print $1}'|tail -n${kill})
           for pid in `echo $pids`; do
           kill $pid
           done
    }
done
sleep 3s
) &
}

while true; do
function_killmultiloguin > /dev/null 2>&1
sleep 7s
done
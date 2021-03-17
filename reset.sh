#!/bin/bash

export SERVER_PORT=8555
export CONSOLE_PORT=7555

# 退出已经启动的服务器
# 通过服务器监听的端口来找到对应的服务器进程,然后退出
servers=`netstat -ntlp | grep $CONSOLE_PORT | sort | awk '{print $NF}' |awk -F'/' '{print $1}'`
for i in $servers
do
	echo $i server is running, stop it now
	skill -9 $i
done

echo start server ...

logFileName="log_0.txt"

if [ -f "$logFileName" ]; then
    logFileMax=`for i in $(ls | grep "log_.*.txt" | grep -o "[0-9]\+");do echo $i;done|sort -nr|head -1`

    if [ $logFileMax -gt 4 ] ; then
        rm log_1.txt
        for ((i=2; i<=$logFileMax; i++))
        do
            logBakFileName1="log_$(($i)).txt"
            logBakFileName2="log_$(($i-1)).txt"
            mv $logBakFileName1 $logBakFileName2
        done

        logBakFileName="log_$(($logFileMax)).txt"
    else
        logBakFileName="log_$(($logFileMax+1)).txt"
    fi

    echo "backup log files: mv" $logFileName "to" $logBakFileName
    mv $logFileName $logBakFileName
fi

# ../skynet/skynet config.lua
/data/skynet_note/skynet config.lua &

sleep 0.1

cat $logFileName

servers=`netstat -ntlp | grep $SERVER_PORT | sort | awk '{print $NF}' |awk -F'/' '{print $1}'`

isStarted=false
for i in $servers
do
    isStarted=true
    echo "====================================================="
    echo $i server started sucessfull
    echo log file is $logFileName
    echo listen on port $SERVER_PORT
    echo "====================================================="

    tail -f -n 0 $logFileName
done

if ! $isStarted; then
    echo "====================================================="
    echo server started failed!!!
    echo log file is $logFileName
    echo "====================================================="
fi

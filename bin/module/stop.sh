#!/bin/bash
###
 # @Date: 2022-07-24 14:28:36
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-09-19 21:50:07
 # @Description: 停止服务器
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "Stop the Minecraft server"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl stop [reason] [-h[mini]]\n"
  GetI18nText Help_module_content "  reason: Reason for shutting down the server"
  return 0;
}

ARGS=`getopt -o h:: -l help:: -- "$@"`
if [ $? != 0 ]; then
  helpMenu > /dev/stderr;exit 1;
fi

# Assign normalized command line arguments to positional arguments($1,$2,...)
eval set -- "${ARGS}"

while true
do
  case "$1" in
    -h|--help)
      helpMenu "$2"
      exit $?
      ;;
    --)
      shift
      break
      ;;
    *)
      GetI18nText Error_Internal "Internal error!" > /dev/stderr;
      exit 1
      ;;
  esac
done

# 检查是否有实例正在运行(如果没有就直接退出)
ExistServerExample
if [ $? -ne 0 ]; then
  GetI18nText Error_NoInstance "No instance is currently running, if you want to start the server, use the \e[1;32mstart\e[0m parameter"
  exit 1
fi
# 向服务器中发出提示
if [ "$1" != "" ]; then
  ToServerMsg=`GetI18nText Info_Server_Close_Prompt_Reason "The server is about to shut down due to ${2}, please be prepared" ${2}`
else
  ToServerMsg=`GetI18nText Info_Server_Close_Prompt "The server will be shut down soon, please be prepared."`
fi
say2server "${ToServerMsg}"
# 等一会
for i in $(seq 10 -1 1); do
  sleep 1
  say2server "${i}"
done
# 停止服务器运行
cmd2server "stop"
# 等待进程退出(如果超过指定的时间没有退出, 就杀死进程)
WaitTime=0
ESE=0
while [ ${ESE} == 0 ] ;
do
  ExistServerExample
  ESE=$?
  sleep 1
  ((WaitTime++))
  if [ ${WaitTime} -gt ${StopWaitTimeMax} ]; then
    screen -S "${ScreenName}" -X quit
  fi
done
unset WaitTimes ESE
eGetI18nText Info_ServerTerminated "${ScreenName} has terminated" ${ScreenName}
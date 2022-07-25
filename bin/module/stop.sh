#!/bin/bash
###
 # @Date: 2022-07-24 14:28:36
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-25 11:50:48
 # @Description: 停止服务器
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 
# TODO 转为新版参数化

source $InstallPath/tools/Base.sh

#* show this help menu
function helpMenu() {
  echo -e "Stop the Minecraft server"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  # echo -e "Usage: minecraftctl say <-m Msg> [-u GameID] [-h[mini]]\n"
  echo -e "Usage: minecraftctl stop [reason] [-h[mini]]\n"
  echo -e "  reason: Reason for shutting down the server"
  # echo -e "  -n,\t--backupname\t\tthe name of the backup file"
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
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Internal error!" > /dev/stderr;
      exit 1
      ;;
  esac
done

# 检查是否有实例正在运行(如果没有就直接退出)
ExistServerExample
if [ $? -ne 0 ]; then
  echo 当前无任何实例正在运行，若是希望启动服务器，使用start参数
  exit 1
fi
# 向服务器中发出提示
if [ "$1" != "" ]; then
  say2server "由于$2,即将关闭服务器，请各位做好准备."
else
  say2server "即将关闭服务器,请各位做好准备."
fi
# 等一会
for i in $(seq 10 -1 1); do
  sleep 1
  say2server "${i}"
done
# 停止服务器运行
cmd2server "stop"
# 等待进程退出(如果超过指定的时间没有退出，就杀死进程)
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
echo "${ScreenName} 已终止运行"
#!/bin/bash
###
 # @Date: 2022-07-24 14:57:20
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-25 11:43:58
 # @Description: 
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

#* show this help menu
function helpMenu() {
  echo -e "Restart the Minecraft server"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  echo -e "Usage: minecraftctl restart [-h[mini]]"
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

# 在启动前先关闭之前的服务
ExistServerExample
if [ $? -ne 0 ]; then
  echo 当前无任何实例正在运行，若是希望启动服务器，使用start参数
else
  $0 stop 重启服务器
fi
# 等待子进程结束
wait $!
$0 start
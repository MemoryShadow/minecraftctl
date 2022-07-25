#!/bin/bash
###
 # @Date: 2022-07-24 14:58:26
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-25 11:35:14
 # @Description: 连接服务器后台控制台
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

# TODO 完成 -b 功能

#* show this help menu
function helpMenu() {
  echo -e "connection server backend"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  echo -e "Usage: minecraftctl join [-h[mini]]\n"
  # echo -e "Usage: minecraftctl join [-b BackendName] [-h[mini]]\n"
  # echo -e "  -b,\t--backend\t\tThe name of the server backend to connect to"
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

ExistServerExample
if [ $? -ne 0 ]; then
  echo 当前无任何实例正在运行，若是希望启动服务器，使用start参数
  exit 1
fi
screen -rd "${ScreenName}"
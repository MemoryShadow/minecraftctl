#!/bin/bash
###
 # @Date: 2022-07-24 15:03:46
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-25 11:51:53
 # @Description: 打开一个视图，可以查看服务器的状态的同时操作终端
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

#* show this help menu
function helpMenu() {
  echo -e "Opens a view where you can view the status of the server while operating the terminal"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  echo -e "Usage: minecraftctl view [-h[mini]]"
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

# 目前还是Beta功能
screen -x -S "minecraftctl" -p 1 -X stuff "minecraftctl join\n"
screen -Rd "minecraftctl" -c /etc/minecraftctl/theme/default
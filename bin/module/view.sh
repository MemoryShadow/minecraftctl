#!/bin/bash
###
 # @Date: 2022-07-24 15:03:46
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-09-19 21:12:02
 # @Description: 打开一个视图，可以查看服务器的状态的同时操作终端
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "[Test]Opens a view where you can view the status of the server while operating the terminal"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl view [-h[mini]]"
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

# 目前还是Beta功能
screen -x -S "minecraftctl" -p 1 -X stuff "minecraftctl join\n"
screen -Rd "minecraftctl" -c /etc/minecraftctl/theme/default
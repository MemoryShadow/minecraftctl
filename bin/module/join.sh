#!/bin/bash
###
 # @Date: 2022-07-24 14:58:26
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-09-08 21:39:48
 # @Description: 连接服务器后台控制台
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

NAME=''

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "connection server backend"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl join [-N Name] [-h[mini]]\n"
  GetI18nText Help_module_content "  -n,\t--name\t\tThe name of the server backend to connect to"
  return 0;
}

ARGS=`getopt -o n:h:: -l name:,help:: -- "$@"`
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
    -n|--name)
      NAME="$2";
      shift 2;
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

ExistServerExample "${NAME:-$ScreenName}"
if [ $? -ne 0 ]; then
  GetI18nText Error_NoInstance "No instance is currently running, if you want to start the server, use the \e[1;32mstart\e[0m parameter"
  exit 1
fi
screen -rd "${ScreenName}"
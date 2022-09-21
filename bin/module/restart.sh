#!/bin/bash
###
 # @Date: 2022-07-24 14:57:20
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-09-19 21:50:02
 # @Description: 
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "Restart the Minecraft server"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl restart [-h[mini]]"
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

# 在启动前先关闭之前的服务
ExistServerExample
if [ $? -ne 0 ]; then
  GetI18nText Error_NoInstance "No instance is currently running, if you want to start the server, use the \e[1;32mstart\e[0m parameter"
else
  reason=`GetI18nText Info_reason "restart the server"`
  minecraftctl stop "${reason}"
fi
# 等待子进程结束
wait $!
minecraftctl start
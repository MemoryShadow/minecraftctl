#!/bin/bash
###
 # @Date: 2022-07-24 14:55:37
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-25 11:31:29
 # @Description: 编辑文件
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

# TODO 完成-m和-s的功能

source $InstallPath/tools/Base.sh

# 在编辑器中打开指定的文件
function openEditer() {
  # 检测当前是否在VSCode中打开
  whereis code | grep :\ / >/dev/null
  if [ $? -eq 0 ]; then
    code $1
  else
    # 尝试自动解决中文乱码的问题
    if [ ! -e ~/.vimrc ]; then
      echo "set enc=utf8">~/.vimrc
    fi
    vim $1
  fi
}

# 编辑配置文件
function EditConfig() {
  if [ $1 ]; then
    case $1 in
    ser | server | server.properties)
      filePath="server.properties"
      ;;
    op | ops | ops.json)
      filePath="ops.json"
      ;;
    wh | wl | whitelist | whitelist.json)
      filePath="whitelist.json"
      ;;
    sp | spigot | spigot.yml)
      filePath="spigot.yml"
      ;;
    cfg | conf | config)
      filePath="/etc/minecraftctl/config"
    ;;
    *)
      return 1
      ;;
    esac
    openEditer $filePath
  fi
}

#* show this help menu
function helpMenu() {
  echo -e "Edit minecraftctl and minecraft related files"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  echo -e "Usage: minecraftctl edit [-h[mini]]\n"
  # echo -e "Usage: minecraftctl edit [-m ModuleName] -[s serverfile] [-h[mini]]\n"
  # echo -e "  -m,\t--module\t\tSpecify the module name to edit"
  # echo -e "  -s,\t--server\t\tSpecifies the server filename to edit"
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

if [ ! $1 ]; then
  openEditer $InstallPath/minecraftctl
else
  EditConfig $1
fi
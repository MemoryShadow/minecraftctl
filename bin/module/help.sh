#!/bin/bash
###
 # @Date: 2022-07-24 15:05:22
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-25 13:23:56
 # @Description: 获取当前软件的帮助菜单
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

# TODO 需要支持多语言

source $InstallPath/tools/Base.sh

#* show this help menu
function helpMenu() {
  if [[ ! -z $1 && "$1" == "mini" ]]; then echo "Get this help menu"; return 0; fi
  echo -e "此脚本用于以尽可能简洁的方式对Minecraft服务端进行控制"
  echo -e "minecraftctl <功能名称> [可能的参数]\n"
  local ModuleList=`ls /opt/minecraftctl/module/`
  ModuleList=(${ModuleList// /})
  local Module=''
  for Module in "${ModuleList[@]}"
  do
    Module=${Module%.*}
    local Separate=
    if [ "${#Module}" -gt 7 ]; then Separate="\n\t\t"; 
    elif [ "${#Module}" -lt 4 ]; then Separate="  \t\t";
    else Separate="  \t"; 
    fi
    local ModuleMiniHelp=`minecraftctl ${Module} -hmini`
    echo -e "  ${Module}${Separate}${ModuleMiniHelp}"
  done
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

echo -e "此脚本用于以尽可能简洁的方式对Minecraft服务端进行控制"
echo -e "minecraftctl <功能名称> [可能的参数]\n"
echo -e "\tinstall\t快速安装Minecraft服务端\n\t\t此功能的高速下载由BMCL项目提供部分加速支持"
echo -e "\trestart\t重启服务器"
echo -e "\tbackup\t备份服务器(如果已经存在实例，就会进行紧急备份)"
echo -e "\tstart\t启动服务器"
echo -e "\tQQMsg\t服务器接收QQ消息"
echo -e "\tstop [理由]\t关闭服务器"
echo -e "\tjoin\t此功能用于连接后台"
echo -e "\tview\t(Beta)此功能用于打开一个\"简易控制台\""
echo -e "\tedit [cfg|ser|op|wh|sp]\t编辑文档功能"
echo -e "\t-h help --help\t此功能用于获取帮助文档"
echo -e "\tsay <要发送的消息> [要模拟的ID]\t向服务器发送消息"
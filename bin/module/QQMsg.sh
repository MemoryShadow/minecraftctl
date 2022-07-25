#!/bin/bash
###
 # @Date: 2022-07-24 12:33:29
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-25 11:40:27
 # @Description: 获取QQ群的消息
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

#* show this help menu
function helpMenu() {
  echo -e "Get the news of the QQ group"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  echo -e "Usage: minecraftctl QQMsg [-h[mini]]"
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

# 解析消息配置
function AnalysisConfiguration() {
  # 先检查在哪个命令池里进行匹配
  case $3 in
  1)
    cmd_list="start,stop,restart,backup"
    cmd_list_arr=(${cmd_list//,/ })
    for i in "${cmd_list_arr[@]}"; do
      if [ $i==$1 ]; then
        # 若是找到匹配，就调用服务器管理工具
        echo $0 $1 " $2 在群内要求"
        $0 $1 " $2 在群内要求"
        return 0
      fi
    done
    ;&
  0)
    cmd_list="say"
    cmd_list_arr=(${cmd_list//,/ })
    for i in "${cmd_list_arr[@]}"; do
      if [ $i==$1 ]; then
        # 若是找到匹配，就调用服务器管理工具
        %0 say $1 $2
        return 0
      fi
    done
    ;;
  esac
}

hostnameStr=`hostname`
$Insecure && curlCmd='curl --insecure'
Msg=$(${curlCmd:-curl} -s -e "${hostnameStr}" -A "${hostnameStr}" "${HostProtocol:-https}://${MasterHost:-master}/Template/Public/ToolAPI/?Function=Robot" -d 'Text=Text&PlayerID=0')
arr_Msg=(${Msg// / })
#*拉取完成后，解析消息配置
echo $Msg
AnalysisConfiguration ${arr_Msg[0]} "${arr_Msg[2]}(${arr_Msg[1]})" ${arr_Msg[3]}

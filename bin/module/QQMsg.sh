#!/bin/bash
###
 # @Date: 2022-07-24 12:33:29
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-09-23 17:38:53
 # @Description: 获取QQ群的消息
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

# TODO 新增-q参数另其保持静默

source $InstallPath/tools/Base.sh

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "Get the news of the QQ group"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl QQMsg [-h[mini]]"
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
        local ToServerMsg=`GetI18nText Info_RequestTheGroup "${2} is requested in the group" ${2}`
        echo $0 $1 ${ToServerMsg}
        $0 $1 ${ToServerMsg}
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

#!/bin/bash
###
 # @Date: 2022-07-24 14:01:03
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-09-21 23:26:50
 # @Description: 向服务器中说话
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

# TODO 新增-o,--origin参数用于标记消息的来源位置

source $InstallPath/tools/Base.sh

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "Send in-game messages"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl say <-m Msg> [-u GameID] [-h[mini]]\n"
  GetI18nText Help_module_content "  -m,\t--msg\t\tMessage to send\n  -u,\t--username\tGame ID to emulate\n  -h,\t--help\t\tShow this help menu"
  return 0;
}

ARGS=`getopt -o -m:u:h:: -l msg:,username:,help:: -- "$@"`
if [ $? != 0 ]; then
  helpMenu > /dev/stderr;exit 1;
fi

# Assign normalized command line arguments to positional arguments($1,$2,...)
eval set -- "${ARGS}"

MSG=''
USERNAME=''

while true
do
  case "$1" in
    -h|--help)
      helpMenu "$2";
      exit $?;
      ;;
    -m|--msg)
      MSG="$2";
      shift 2;
      ;;
    -u|--username)
      USERNAME="$2";
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

# 向服务器发送信息
function say2server() {
  if [ "$2" != "" ]; then
    if [ "$1" != "" ]; then
      local Info_Emulate_clickEvent=`GetI18nText Info_Emulate_clickEvent "!!qq "`;
      local Info_Emulate_hoverEvent=`GetI18nText Info_Emulate_hoverEvent "The news comes from the QQ group"`;
      cmd2server "tellraw @a {\"text\":\"<\",\"extra\":[{\"text\":\"${2}\",\"clickEvent\":{\"action\":\"suggest_command\",\"value\":\"${Info_Emulate_clickEvent}\"},\"hoverEvent\":{\"action\":\"show_text\",\"value\":\"${Info_Emulate_hoverEvent}\"},\"color\":\"white\"},{\"text\":\"> \"},{\"text\":\"${1:-发送了一条消息, 请前往QQ群查看}\"}]}"
    fi
  else
    if [ "$1" != "" ]; then
      cmd2server "say $1"
    fi
  fi

  return 0;
}

if [ "${USERNAME}" != "" ]; then
  say2server "${MSG}" "${USERNAME}"
else
  say2server "${MSG}"
fi
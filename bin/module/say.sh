#!/bin/bash
###
 # @Date: 2022-07-24 14:01:03
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-25 11:46:41
 # @Description: 向服务器中说话
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 
# TODO 转为新版参数化

source $InstallPath/tools/Base.sh

#* show this help menu
function helpMenu() {
  echo -e "Send in-game messages"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  # echo -e "Usage: minecraftctl say <-m Msg> [-u GameID] [-h[mini]]\n"
  echo -e "Usage: minecraftctl say <Msg> [GameID] [-h[mini]]\n"
  echo -e "  Msg: Message to send"
  echo -e "  GameID: Game ID to emulate"
  # echo -e "  -n,\t--backupname\t\tthe name of the backup file"
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

# 向服务器发送信息
function say2server() {
  if [ "$2" != "" ]; then
    if [ "$1" != "" ]; then
      cmd2server "tellraw @a {\"text\":\"<\",\"extra\":[{\"text\":\"$2\",\"clickEvent\":{\"action\":\"suggest_command\",\"value\":\"!!qq \"},\"hoverEvent\":{\"action\":\"show_text\",\"value\":\"消息来自QQ群\"},\"color\":\"white\"},{\"text\":\"> \"},{\"text\":\"$1\"}]}"
    fi
  else
    if [ "$1" != "" ]; then
      cmd2server "say $1"
    fi
  fi

  return 0
}

if [ "$2" != "" ]; then
    say2server $1 $2
  else
    say2server $1
fi
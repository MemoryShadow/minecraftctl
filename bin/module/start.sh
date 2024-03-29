#!/bin/bash
###
 # @Date: 2022-07-24 14:30:58
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-01-08 22:53:02
 # @Description: 启动服务器
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 
source $InstallPath/tools/Base.sh

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "Start the Minecraft server"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl start [-h[mini]]"
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

ExistServerExample
if [ $? -eq 0 ]; then
  GetI18nText Error_InstanceExists "There is already a running instance, if you want to restart the server, use the \e[1;32mrestart\e[0m parameter"
  exit 1
else
  # 启动服务器
  ExtraParameters='';
  $Authlib && ExtraParameters="${ExtraParameters:+ }-javaagent:authlib-injector-${AuthlibInjectorVer}.jar=${AuthlibInjector} ";
  "$InstallPath/tools/JvmCheck.sh" -p "${JvmPath}"
  if [ $? == 2 ]; then 
    ExtraParameters="${ExtraParameters:+ }-Xtune:virtualized -XX:+AggressiveOpts -XX:+UseCompressedOops "
  fi
  cmd=${cmd:-"${JvmPath:-java}"}" -server ${UserExtraParameters:+${UserExtraParameters} }${ExtraParameters}-Xss512K -Xmx${MaxCache}M -Xms${StartCache}M -jar ${MainJAR}.jar nogui | minecraftctl listen; exit 0;"
  # 创建一个对应名称的会话
  screen -dmS "$ScreenName"
  cmd2server "${cmd}"
  GetI18nText Info_CommandSubmitted "${ScreenName} has submitted the startup command" "${ScreenName}"
fi
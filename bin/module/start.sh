#!/bin/bash
###
 # @Date: 2022-07-24 14:30:58
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-25 11:47:26
 # @Description: 启动服务器
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 
source $InstallPath/tools/Base.sh

#* show this help menu
function helpMenu() {
  echo -e "Start the Minecraft server"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  echo -e "Usage: minecraftctl start [-h[mini]]"
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

ExistServerExample
if [ $? -eq 0 ]; then
  echo 当前已经有正在运行的实例，若是希望重启服务器，使用restart参数
  exit 1
else
  # 启动服务器
  $Authlib && cmd="${JvmPath:-java} -server -javaagent:authlib-injector-${AuthlibInjectorVer}.jar=${AuthlibInjector}"
  cmd=${cmd:-"${JvmPath:-java} -server"}" -Xss512K -Xmx${MaxCache}M -Xms${StartCache}M -jar ${MainJAR}.jar nogui | minecraftctl listen;"
  # 创建一个对应名称的会话
  screen -dmS "$ScreenName"
  cmd2server "$cmd"
  echo "${ScreenName} 已提交启动命令,正在启动..."
fi
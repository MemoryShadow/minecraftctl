#!/bin/bash
###
 # @Date: 2022-07-24 12:35:58
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-25 11:11:51
 # @Description: 为其他函数提供基本的函数库与初始加载
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 


if [ -f ${GamePath}/minecraftctl.conf ]; then
  source ${GamePath}/minecraftctl.conf
fi

# 加载局部配置覆盖全局配置, 当前目录中的minecraftctl.conf文件优先级最高
if [ -f $WorkDir/minecraftctl.conf ]; then
  source $WorkDir/minecraftctl.conf
else
  if [ -f ${GamePath}/minecraftctl.conf ]; then
    source ${GamePath}/minecraftctl.conf
  fi
  # 如果工作目录没有配置,就前往配置中的目录
  if [ ! -d ${GamePath} ]; then
    mkdir -p ${GamePath}
  fi
  cd ${GamePath}
fi

# 返回服务器核心版本,0表示配置错误,1表示官方核心,2表示非官方核心
function GetServerCoreVersion() {
  case ${ServerCore} in
  official | forge)
    return 1
    ;;
  unofficial|bukkit|spigot|paper|purpur|airplane)
    return 2
    ;;
  *)
    return 0
    ;;
  esac
}

# 检查是否有服务器实例已经存在,如果存在则返回0，否则返回其他值
function ExistServerExample() {
  screen -ls | grep "${ScreenName//[/\\[}" >/dev/null 2>/dev/null
}

# 向服务器发送命令
function cmd2server() {
  if [ "$1" != "" ]; then
    screen -x -S "$ScreenName" -p 0 -X stuff "$1\n"
  fi
  return 0
}
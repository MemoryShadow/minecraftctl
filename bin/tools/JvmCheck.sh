#!/bin/bash
###
 # @Date: 2022-07-06 14:23:58
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-06 18:51:50
 # @Description: Jvm Check
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

function JvmVersionCheck() {
    if [ ${1%%.*} != 1 ]; then
        return ${1%%.*}
    else
        JvmVersion=${1#*.}
        return ${JvmVersion%.*}
    fi
}

function JvmNameCheck() {
  if [ "${1}" == "Server" ]; then
    # Hotspot
    return 1
  elif [ "${1}" == "OpenJ9" ]; then
    # OpenJ9
    return 2
  fi
}

JvmList=`find /usr/lib/jvm/ | grep -e "/java$"`
JvmList=(${JvmList// /})
for Jvm in "${JvmList[@]}"
do
  # 检测已经安装的JVM版本
  JvmInfo=`"${Jvm}" -version 2>&1`
  JvmVersion=${JvmInfo#*\"};JvmVersion=${JvmVersion%\"*};
  JvmVersionCheck ${JvmVersion}
  JvmVersion=$?
  JvmName=${JvmInfo%% VM*}; JvmName=${JvmName##* };
  JvmNameCheck ${JvmName}
  JvmName=$?
  echo $JvmName ${JvmVersion}
done
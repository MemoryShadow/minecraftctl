#!/bin/bash
###
 # @Date: 2022-07-06 14:23:58
 # @Author: MemoryShadow
 # @LastEditors: error: git config user.name && git config user.email & please set dead value or install git
 # @LastEditTime: 2022-07-22 12:01:40
 # @Description: Check which JVM should be used to start the specified task, if there is no suitable JVM try to help
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

declare -A TaskConfig=(
  ['build']="build"
  ['run']="run"
)

# TaskConfig list

declare -A TaskConfig_default=(
  ['JvmName']=0
  ['Critical']="1.18.2,1.17,1.0.0"
  ['latest']="1.19"
  ['1.0.0']=8
  ['1.17']=17
  ['1.18.2']=18
)

declare -A TaskConfig_build=(
  ['JvmName']=0
)

declare -A TaskConfig_run=(
  ['JvmName']=2
)

#*将Java -version中返回的版本号转为对应的版本号以供其他程序使用
#?@param $1: Java版本号
#?@return: Java版本号
function GetJvmVersion() {
    if [ ${1%%.*} != 1 ]; then
        return ${1%%.*}
    else
        JvmVersion=${1#*.}
        return ${JvmVersion%.*}
    fi
}

#*将Jvm返回的关键名称转为对应的代号以供其他程序使用
#?@param $1: Jvm路径
#?@return: 1: HotSpot 2: OpenJ9
function GetJvmName() {
  if [ "${1}" == "Server" ]; then
    # Hotspot
    return 1
  elif [ "${1}" == "OpenJ9" ]; then
    # OpenJ9
    return 2
  fi
}

#*检查指定的Jvm相关信息
#?@param $1: Jvm路径
#?@return(echo) Jvm相关信息
function JvmCheck() {
  local JvmInfo=`"${1}" -version 2>&1`
  local JvmVersion=${JvmInfo#*\"};JvmVersion=${JvmVersion%\"*};
  GetJvmVersion ${JvmVersion}
  JvmVersion=$?
  local JvmName=${JvmInfo%% VM*}; JvmName=${JvmName##* };
  GetJvmName ${JvmName}
  JvmName=$?
  echo "${JvmName},${JvmVersion}"
}

#*比对两个游戏版本
#?@param $1: 游戏版本1
#?@param $2: 游戏版本2
#?@return 0: 相同 1:左边版本大于右边版本($1>$2) 2:左边版本小于右边版本($1<$2)
function GameVersionCompare() {
  # 分割版本号为数组
  local LeftVersion=(${1//./ })
  local RightVersion=(${2//./ })
  local Version=''

  # 如果右侧的版本数量大于左侧的版本数量，则左侧的版本数量补齐0
  if [ ${#RightVersion[@]} -gt ${#LeftVersion[@]} ]; then
  for ((i=0;i<(${#RightVersion[@]}-${#LeftVersion[@]});i++))
    do
      LeftVersion[${#LeftVersion[@]}]=0
    done
  fi

  # 循环比较版本号
  for Version in ${!LeftVersion[@]}
  do
    if [[ ${LeftVersion[$Version]} != ${RightVersion[$Version]} ]]; then
      if [[ ${LeftVersion[$Version]} -gt ${RightVersion[$Version]} ]]; then
        return 1
      else
        return 2
      fi
    fi
  done
  return 0
}

#*在给定的列表中找到低于给定版本的最小版本
#?@param $1: 指定的降序列表(必须是已经排好序的)
#?@param $2: 指定的版本
#?@return(echo) 低于给定版本的最小版本
function GameVersionFind() {
  # 解析给定的列表
  local GameVersionList=(${1//,/ })
  local Version=''
  
  # 循环比较版本号
  for Version in ${GameVersionList[@]}
  do
    GameVersionCompare $Version ${2}
    if [[ $? != 1 ]]; then
      echo "$Version"
      return 0
    fi
  done
  return 1
}

# function JvmSuggest(){}


#* show this help menu
function helpMenu() {
  echo -e "Check which JVM should be used to start the specified task, if there is no suitable JVM try to help"
  echo -e "${0} -a <build|run> -v <version> [-h]"
  echo -e "  -a,\t--action\tThe URL of the file waiting to be downloaded"
  echo -e "  -v,\t--version\ttarget game version, defaults to \"latest\""
  echo -e "  -h,\t--help\t\tGet this help menu"
}

ARGS=`getopt -o a:v:h -l action:,version:,help -- "$@"`
if [ $? != 0 ]; then
  helpMenu > /dev/stderr;exit 50;
fi

# Assign normalized command line arguments to positional arguments($1,$2,...)
eval set -- "${ARGS}"

ACTION=''
VERSION='latest'

while true
do
  case "$1" in
    -a|--action)
      ACTION="$2";
      shift 2
      ;;
    -v|--version)
      VERSION="$2";
      shift 2
      ;;
    -h|--help)
      helpMenu
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Internal error!" > /dev/stderr;
      exit 49
      ;;
  esac
done

if [[ -z "${ACTION}" || -z "${TaskConfig[$ACTION]}" ]]; then echo -e "The parameter does not exist or the action is unknown, please pass in the action to be executed\n" > /dev/stderr; helpMenu > /dev/stderr; exit 2; fi;

# 根据任务加载对应的配置信息
cp_source="TaskConfig_${TaskConfig[${ACTION}]}"
cp_dest="ThisTaskUniqueConfig"
temp=`declare -p ${cp_source}`
eval "${temp/${cp_source}=/${cp_dest}=}"
unset temp cp_source cp_dest

# 带key的数组拷贝TaskConfig_default->ThisTaskConfig
temp=`declare -p TaskConfig_default`
eval "${temp/TaskConfig_default=/ThisTaskConfig=}"
unset temp

# 将配置信息合并到ThisTaskConfig中
for key in ${!ThisTaskUniqueConfig[@]}
do
  if [[ ! -z "${ThisTaskUniqueConfig[${key}]}" ]]; then
    ThisTaskConfig[${key}]=${ThisTaskUniqueConfig[${key}]}
  fi
done

unset ThisTaskUniqueConfig

if [ $VERSION == 'latest' ]; then VERSION=${ThisTaskConfig[latest]}; fi
if [ ! -d '/usr/lib/jvm/' ]; then echo -e "Unable to find Java on the system, if you confirm that Java is installed, use the ln command to link it to the directory /usr/lib/jvm/" > /dev/stderr; exit 127; fi

# 检查本机java信息
JvmList=`find /usr/lib/jvm/ | grep -e "/java$"`
JvmList=(${JvmList// /})
# 取得合适的游戏版本
SelectGameVersion=`GameVersionFind "${ThisTaskConfig[Critical]}" $VERSION`
# 获取Jvm版本信息并写入AvailableJvmList中，等待后续的判断
for Jvm in "${JvmList[@]}"
do
  # 检测已经安装的JVM版本, 并根据请求的任务保存请求的JVM版本
  JvmInfo=`JvmCheck $Jvm`
  JvmInfo=(${JvmInfo/,/ })
  # 将符合版本条件的Jvm信息保存到AvailableJvmList中(复用)
  if [ "${JvmInfo[1]}" == "${ThisTaskConfig[${SelectGameVersion}]}" ]; then
    AvailableJvmList[${#AvailableJvmList[@]}]="${JvmInfo[0]},${Jvm}"
  fi
done

if [ ${#AvailableJvmList[@]} == 0 ]; then echo -e "No suitable Java found, please try to install the Java ${ThisTaskConfig[${SelectGameVersion}]}\n" > /dev/stderr; exit 3; fi

# 判断是否有合适的JVM实现，如果没有，就返回次一级的并返回1
for JvmInfo in "${AvailableJvmList[@]}"
do
  JvmInfo=(${JvmInfo/,/ })
  if [[ "${ThisTaskConfig[JvmName]}" == "0" || "${JvmInfo[0]}" == "${ThisTaskConfig[JvmName]}" ]]; then
    echo "${JvmInfo[1]}"
    exit 0
  fi
done
# 如果到这里还没有退出，就直接返回一个勉强满意的回去并回复1
JvmInfo=${AvailableJvmList[0]/,/ }
echo "${JvmInfo[1]}"
exit 1
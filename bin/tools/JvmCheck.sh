#!/bin/bash
###
 # @Date: 2022-07-06 14:23:58
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-07-19 13:54:22
 # @Description: Check which JVM should be used to start the specified task, if there is no suitable JVM try to help
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

declare -A TaskConfig=(
  ['build']="build"
  ['run']="run"
)

# TaskConfig list

declare -A TaskConfig_default=(
  ['JvmName']=0
  # 记录Java版本重要的转折点
  ['Critical']="1.19.2,1.18.2,1.18.1,1.17,1.0.0"
  ['latest']="1.19"
  ['1.0.0']='8'
  ['1.17']='16,17'
  ['1.18.1']='17'
  ['1.18.2']='17,18'
  ['1.19.2']='17,19'
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
    return 1;
  elif [ "${1}" == "OpenJ9" ]; then
    # OpenJ9
    return 2;
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
  GetI18nText Help_module_Introduction "Check which JVM should be used to start the specified task, if there is no suitable JVM try to help"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: ${0} -a <build|run> -v <version> [-p <Path>] [-h[mini]]\n" ${0}
  GetI18nText Help_module_content "  -a,\t--action\tAction waiting to be executed, allowed values: build,run\
\n  -v,\t--version\ttarget game version, defaults to \"latest\"\
\n  -p,\t--path\t\tDetect what JVM is the specified Java, 1: HotSpot 2: OpenJ9\
\n  -h,\t--help\t\tGet this help menu"
}

ARGS=`getopt -o a:v:p:h:: -l action:,version:,path:,help:: -- "$@"`
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
    -p|--path)
      JvmName=`"${2}" -version 2>&1`
      JvmName=${JvmName%% VM*}; JvmName=${JvmName##* };
      GetJvmName "${JvmName}"
      exit $?
      ;;
    -h|--help)
      helpMenu "$2";
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      GetI18nText Error_Internal "Internal error!" > /dev/stderr;
      exit 49
      ;;
  esac
done

if [[ -z "${ACTION}" || -z "${TaskConfig[$ACTION]}" ]]; then GetI18nText Error_Missing_parameters_Action "The parameter \"${ACTION}\" does not exist or the action is unknown, please pass in the action to be executed\n" ${ACTION} > /dev/stderr; helpMenu > /dev/stderr; exit 2; fi;

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
if [ ! -d '/usr/lib/jvm/' ]; then GetI18nText Info_NotFoundJVM "Unable to find JVM on the system, if you confirm that JVM is installed, use the ln command to link it to the directory /usr/lib/jvm/" > /dev/stderr; exit 127; fi

# 检查本机java信息
JvmList=`find /usr/lib/jvm/ -iregex ".*/bin/java$"`
JvmList=(${JvmList// /})
# 取得合适的游戏版本
SelectGameVersion=`GameVersionFind "${ThisTaskConfig[Critical]}" $VERSION`
# 接受的版本列表
AllowJvmVerList="${ThisTaskConfig[${SelectGameVersion}]}" > /dev/stderr
# 获取Jvm版本信息并写入AvailableJvmList中，等待后续的判断
for Jvm in "${JvmList[@]}"
do
  # 检测已经安装的JVM版本, 并根据请求的任务保存请求的JVM版本
  JvmInfo=`JvmCheck $Jvm`
  JvmInfo=(${JvmInfo/,/ })
  # 将符合版本条件的Jvm信息保存到AvailableJvmList中(复用)
  grep -wq "${JvmInfo[1]}" <<< "${AllowJvmVerList//,/ }"
  if [ "$?" == "0" ]; then
    AvailableJvmList[${#AvailableJvmList[@]}]="${JvmInfo[0]},${Jvm}"
  fi
done
if [ ${#AvailableJvmList[@]} == 0 ]; then GetI18nText Info_NoSuitableJavaFound "No suitable Java found, please try to install the Java ${ThisTaskConfig[${SelectGameVersion}]}\n" ${ThisTaskConfig[${SelectGameVersion}]} > /dev/stderr; exit 3; fi

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
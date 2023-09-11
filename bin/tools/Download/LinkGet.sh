#!/bin/bash
###
 # @Date: 2022-07-06 11:11:33
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-09-09 15:07:38
 # @Description: Get file download parameters for the specified item and game version
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

# Get paper version
#? @param $1|must: game version or latest
function paper(){
  local version=$1
  # Check whether the version is a keyword, if so, automatically query the latest version
  if [ "$1" == "latest" ]; then
    version=`curl -s "https://papermc.io/api/v2/projects/paper"`;version=${version##*,\"};version=${version%%\"*}
  else
    # Check if the version exists
    curl -s "https://papermc.io/api/v2/projects/paper" | grep -qw "${version}"
  fi
  # (0)
  if [ $? != 0 ]; then return 2;fi
  # Get the latest build name
  local build=`curl -s "https://papermc.io/api/v2/projects/paper/versions/${version}"`;build=${build##*,};build=${build%%]*};
  # Get file name
  local filename=`curl -s "https://papermc.io/api/v2/projects/paper/versions/${version}/builds/${build}"`;
  filename=${filename##*application\":\{\"name\":\"};filename=${filename%%\"*}
  echo "--url=https://papermc.io/api/v2/projects/paper/versions/${version}/builds/${build}/downloads/${filename}"
  return 0;
}

# Get purpur version
#? @param $1|must: game version or latest
function purpur(){
  local version=$1
  # Check whether the version is a keyword, if so, automatically query the latest version
  if [ "$1" == "latest" ]; then
    version=`curl -s "https://api.purpurmc.org/v2/purpur"`;version=${version##*,\"};version=${version%%\"*}
  else
    # Check if the version exists
    curl -s "https://api.purpurmc.org/v2/purpur" | grep -qw "$1"
  fi
  # (0)
  if [ $? != 0 ]; then return 2;fi
  # Get the latest download URL
  echo "--url=https://api.purpurmc.org/v2/purpur/${version}/latest/download?name=purpur-${version}.jar"
  return 0;
}

# Get mohist version
#? @param $1|must: game version or latest
function mohist(){
  declare -A versionList=(
    ['1.7.1']='1.7.10'
    ['1.7.10']='1.7.10'
    ['1.12.2']='1.12.2'
    ['1.16.5']='1.16.5'
    ['1.18.2']='1.18.2'
    ['1.19.2']='1.19.2'
    ['1.19.4']='1.19.4'
    ['1.20.1']='1.20.1'
    ['latest']='1.20.1'
  )
  if [ -z ${versionList[$1]} ]; then
    return 2;
  else
    local URL=`curl -s https://mohistmc.com/api/${versionList[$1]}/latest`
    URL=${URL%\",*};URL=${URL%\",*};echo "--url=${URL##*:\"}";
    return 0;
  fi;
}

# Get forge version
#? @param $1|must: game version or latest
function forge(){
  local version=$1
  # Check whether the version is a keyword, if so, automatically query the latest version
  if [ "$1" == "latest" ]; then
    version=`curl -s "https://bmclapi2.bangbang93.com/forge/last"`;version=${version#*mcversion\":\"};version=${version%%\"*}
  else
    # Check if the version exists
    curl -s "https://bmclapi2.bangbang93.com/forge/minecraft" | grep -qw "${version}"
  fi
  # (0)
  if [ $? != 0 ]; then return 2;fi
  # Get the latest build name
  local build=`curl -s "https://bmclapi2.bangbang93.com/forge/minecraft/${version}"`;
  
  # 将build号作为基准点，查找该条配置
  local buildID=`grep -oP '"build":[0-9]*?,' <<< "${build}"`
  buildID=(${buildID//,/ })
  # 收集每一行的信息，由于是无序列表，只能逐个查找, 速度比较慢
  local MaxBuildID=0
  local ThisBuildID=0
  for ThisBuildID in ${buildID[@]}; do
    if [ ${ThisBuildID##*:} -gt ${MaxBuildID} ]; then
      MaxBuildID=${ThisBuildID##*:}
    fi
  done
  buildID=${MaxBuildID}
  ## 通过buildID查找文件hash
  local FileHash=`grep -oP "\"build\":${buildID}.*?\"jar.*?hash\":\"[0-9a-z]*" <<< "$build"`; FileHash=${FileHash##*\"}
  # echo download link
  local URL=`curl -s "https://bmclapi2.bangbang93.com/forge/download/${buildID}"`
  echo "--url=https://files.minecraftforge.net/${URL#*\/} --sha1=${FileHash}"
  return 0;
}

# Get authlib-injector version
function authlib-injector(){
  local DLLink=`curl -s "https://bmclapi2.bangbang93.com/mirrors/authlib-injector/artifact/latest.json"`
  DLLink=${DLLink#*authlib-injector\/}
  local FileHash=${DLLink#*sha256\": \"};FileHash=${FileHash%\"*}
  echo "--url=https://authlib-injector.yushi.moe/${DLLink%%\"*} --sha256=${FileHash}"
  return 0;
}

# Get vanilla version
#? @param $1|must: game version or latest
function vanilla(){
  local version=$1
  if [ "$1" == "latest" ]; then
    version=`curl -s "https://papermc.io/api/v2/projects/paper"`;version=${version##*,\"};version=${version%%\"*}
  fi
  local DLLink=`curl -s "https://bmclapi2.bangbang93.com/version/${version}/server"`
  if [ "$DLLink" == "Not Found" ]; then 
    return 2;
  else
    DLLink=${DLLink#*\/}
    local FileHash=${DLLink%\/*};FileHash=${FileHash##*\/}
    echo "--url=https://launcher.mojang.com/$DLLink --sha1=${FileHash}"
    return 0;
  fi
}

# Get spigot version
#? @param $1|must: game version or latest
function spigot(){
  local version=$1
  if [ "$1" == "latest" ]; then
    version=`curl -s "https://papermc.io/api/v2/projects/paper"`;version=${version##*,\"};version=${version%%\"*}
  fi
  local VerInfo=`curl -s https://serverjars.com/api/fetchAll/spigot/`
  grep -qoP "version\":\"$version.*?md5\":\"[0-9a-z]*" <<< "$VerInfo"
  if [ "$?" == "1" ]; then 
    return 2;
  else
    VerInfo=`grep -oP "version\":\"$version.*?md5\":\"[0-9a-z]*" <<< "$VerInfo"`
    local FileName=`grep -oP "file[\"|:]*[0-9a-z-.]*" <<< "$VerInfo"`
    echo "--url=https://serverjars.com/api/fetchJar/spigot/$version --output=${FileName##*\"} --md5=${VerInfo##*\"}"
    return 0;
  fi
}

# Get bukkit version
#? @param $1|must: game version or latest
function bukkit(){
  local version=$1
  if [ "$1" == "latest" ]; then
    version=`curl -s "https://papermc.io/api/v2/projects/paper"`;version=${version##*,\"};version=${version%%\"*}
  fi
  local VerInfo=`curl -s https://serverjars.com/api/fetchAll/bukkit/`
  grep -qoP "version\":\"$version.*?md5\":\"[0-9a-z]*" <<< "$VerInfo"
  if [ "$?" == "1" ]; then 
    return 2;
  else
    VerInfo=`grep -oP "version\":\"$version.*?md5\":\"[0-9a-z]*" <<< "$VerInfo"`
    local FileName=`grep -oP "file[\"|:]*[0-9a-z-.]*" <<< "$VerInfo"`
    echo "--url=https://serverjars.com/api/fetchJar/bukkit/$version --output=${FileName##*\"} --md5=${VerInfo##*\"}"
    return 0;
  fi
}

# Get tuinity version
#? @param $1|must: game version or latest
function tuinity(){
  local version=$1
  if [ "$1" == "latest" ]; then
    version=`curl -s "https://papermc.io/api/v2/projects/paper"`;version=${version##*,\"};version=${version%%\"*}
  fi
  local VerInfo=`curl -s https://serverjars.com/api/fetchAll/tuinity/`
  grep -qoP "version\":\"$version.*?md5\":\"[0-9a-z]*" <<< "$VerInfo"
  if [ "$?" == "1" ]; then 
    return 2;
  else
    VerInfo=`grep -oP "version\":\"$version.*?md5\":\"[0-9a-z]*" <<< "$VerInfo"`
    local FileName=`grep -oP "file[\"|:]*[0-9a-z-.]*" <<< "$VerInfo"`
    echo "--url=https://serverjars.com/api/fetchJar/tuinity/$version --output=${FileName##*\"} --md5=${VerInfo##*\"}"
    return 0;
  fi
}

# Get cat version
#? @param $1|must: game version or latest
function cat(){
  declare -A versionList=(
    ['1.12.2']='0'
    ['1.16.5']='1'
    ['latest']='1'
  )
  if [ -z ${versionList[$1]} ]; then
    return 2;
  else
    local VerInfo=`curl -s https://api.github.com/repos/Luohuayu/CatServer/releases | grep -oP "browser_download_url[\": ]*https://[a-zA-Z0-9/\-.]*"`
    VerInfo=`grep -oP "https.*?.jar" <<< "${VerInfo// /}"`
    VerInfo=(${VerInfo})
    URL="${VerInfo[${versionList[$1]}]}"
    URL=${URL%\",*};URL=${URL%\",*};echo "--url=${URL##*:\"}";
    return 0;
  fi;
}

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "Get file download parameters for the specified item and game version"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: ${0} -i <item> [-v <version>] [-h[mini]]"
  GetI18nText Help_module_content "  -i,\t--item\t\tThe entry to be retrieved, the allowed values are as follows:\n\t\t\t  vanilla, forge, authlib-injector, mohist, purpur, paper, spigot, bukkit\n  -v,\t--version\tThe version of the game to retrieve, defaults to the latest if left blank\n  -h,\t--help\t\tGet this help menu"
}

ARGS=`getopt -o i:v:h:: -l item:,version:,help:: -- "$@"`
if [ $? != 0 ]; then
    helpMenu > /dev/stderr;exit 1;
fi

# Assign normalized command line arguments to positional arguments（$1,$2,...)
eval set -- "${ARGS}"

ITEM='vanilla'
VERSION='latest'

while true
do
  case "$1" in
    -i|--item)
      ITEM="$2";
      shift 2
      ;;
    -v|--version)
      VERSION="$2";
      shift 2
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
      exit 1
      ;;
  esac
done

if [ -z "${ITEM}" ]; then GetI18nText Error_Missing_parameters_Item "The parameter does not exist, please pass in the item to be queried\n" > /dev/stderr; helpMenu > /dev/stderr; exit 1; fi;

if [ "$(type -t ${ITEM})" == function ]; then
  Result=`${ITEM} ${VERSION}`
else
  GetI18nText Error_Not_Supported_Item "The item is not supported, please set a valid value for \"item\"\n" > /dev/stderr;
  helpMenu > /dev/stderr;
  exit 127;
fi
case "$?" in
  0)
    echo -e "${Result}"
    exit 0;
    ;;
  2)
    GetI18nText Error_Version_Not_Exist "Version does not exist, script has exited\n" > /dev/stderr;
    helpMenu > /dev/stderr;
    exit 2;
    ;;
  *)
    GetI18nText Error_Unknown "Unknown error, script has exited : $?" > /dev/stderr;
    exit 1;
    ;;
esac
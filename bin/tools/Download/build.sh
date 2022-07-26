#!/bin/bash
###
 # @Date: 2022-07-04 09:47:51
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-25 15:58:15
 # @Description: Quickly build spigot or craftbukkit server and move to current working directory
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

#* show this help menu
function helpMenu() {
  echo -e "Quickly build spigot or craftbukkit server and move to current working directory"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  echo -e "${0} [-c <BuildTarget>] [-v <version>] [-h[mini]]"
  echo -e "  -c,\t--compile\t\tTarget to build, defaults to \"spigot\", allowed values are as follows:\n\t\t\t  spigot, craftbukkit"
  echo -e "  -v,\t--version\ttarget game version, defaults to \"latest\""
  echo -e "  -h,\t--help\t\tGet this help menu"
}

ARGS=`getopt -o c:v:h:: -l compile:,version:,help:: -- "$@"`
if [ $? != 0 ]; then
  helpMenu > /dev/stderr;exit 1;
fi

# Assign normalized command line arguments to positional arguments($1,$2,...)
eval set -- "${ARGS}"

COMPILE='spigot'
VERSION='latest'

while true
do
  case "$1" in
    -c|--compile)
      COMPILE="$2";
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
      echo "Internal error!" > /dev/stderr;
      exit 1
      ;;
  esac
done

# 如果compile参数存在, 就检测是否合法
if [[ ! -z "${COMPILE}" && ! "${COMPILE}" =~ ^(spigot|craftbukkit)$ ]]; then
  echo -e "The parameter does not exist or the item is unknown, please pass in the item to be executed\n" > /dev/stderr; helpMenu > /dev/stderr; exit 2;
fi

# 如果VERSION为latest, 就获取真正的版本号
if [ "$VERSION" == "latest" ]; then
  VERSION=`curl -s "https://papermc.io/api/v2/projects/paper"`;VERSION=${VERSION##*,\"};VERSION=${VERSION%%\"*}
fi

# rm -rf /tmp/buildtools [Debug]
if [ ! -d /tmp/buildtools ]; then
  mkdir -p /tmp/buildtools/work
fi
work_dir=`pwd`
cd /tmp/buildtools/
if [ ! -f BuildTools.jar ] ; then
  wget https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
fi;

DownloadPara=`bash /opt/minecraftctl/tools/Download/LinkGet.sh -i vanilla -v $VERSION`
minecraftctl download $DownloadPara -o "work/minecraft_server.$VERSION.jar"
# 检测java版本
JvmPath=`bash /opt/minecraftctl/tools/JvmCheck.sh -a build -v $VERSION`
# 构建(构建要求必须由完全符合的jvm版本运行,不允许"勉强")
if [ $? == 0 ]; then
  $JvmPath -jar BuildTools.jar -rev $VERSION
  mv /tmp/buildtools/spigot-$VERSION.jar $work_dir/
else
  exit 1
fi;

#!/bin/bash
###
 # @Date: 2022-07-04 09:47:51
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-01-01 14:14:37
 # @Description: Quickly build spigot or craftbukkit server and move to current working directory
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "Quickly build spigot or craftbukkit server and move to current working directory"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "${0} [-c <BuildTarget>] [-v <version>] [-h[mini]]"
  GetI18nText Help_module_content "  -c,\t--compile\t\tTarget to build, defaults to \"spigot\", allowed values are as follows:\n\t\t\t  spigot, craftbukkit\n  -v,\t--version\ttarget game version, defaults to \"latest\"\n  -h,\t--help\t\tGet this help menu"
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
      GetI18nText Error_Internal "Internal error!" > /dev/stderr;
      exit 1
      ;;
  esac
done

# 如果compile参数存在, 就检测是否合法
if [[ ! -z "${COMPILE}" && ! "${COMPILE}" =~ ^(spigot|craftbukkit)$ ]]; then
  GetI18nText Error_Missing_parameters_item "The parameter does not exist or the item is unknown, please pass in the item to be executed\n" > /dev/stderr; helpMenu > /dev/stderr; exit 2;
fi

# 如果VERSION为latest, 就获取真正的版本号
if [ "$VERSION" == "latest" ]; then
  VERSION=`curl -s "https://papermc.io/api/v2/projects/paper"`;VERSION=${VERSION##*,\"};VERSION=${VERSION%%\"*}
fi

if [ ! -d /tmp/buildtools ]; then
  mkdir -p /tmp/buildtools/work
fi
work_dir=`pwd`
cd /tmp/buildtools/
if [ ! -e BuildTools.jar ] ; then
  minecraftctl download --url="https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"
fi

# 依照此文章进行提前下载: https://www.mcbbs.net/thread-1285303-1-1.html
# 需要预下载的资源如下: server.jar=>minecraft_server.$VERSION.jar, Maven-3.6.0(并修改<mirrors>字段), builddata.git, bukkit.git, craftbukkit.git, spigot.git

if [ ! -d work ]; then mkdir -p work; fi
if [ ! -e "work/minecraft_server.$VERSION.jar" ] ; then
  DownloadPara=`${InstallPath}/tools/Download/LinkGet.sh -i vanilla -v $VERSION`
  minecraftctl download $DownloadPara -o "work/minecraft_server.$VERSION.jar"
fi

if [ ! -d "apache-maven-3.6.0" ]; then 
  minecraftctl download --url="https://static.spigotmc.org/maven/apache-maven-3.6.0-bin.zip"
  unzip apache-maven-3.6.0-bin.zip; rm apache-maven-3.6.0-bin.zip;
fi
# 修改mirrors字段
grep 'aliyun' apache-maven-3.6.0/conf/settings.xml
if [ "$?" == "1" ]; then
  sed -i 's/<mirrors>/<mirrors>\
    <mirror>\
      <id>nexus\-aliyun<\/id>\
      <name>Nexus aliyun<\/name>\
      <url>http:\/\/maven.aliyun.com\/nexus\/content\/groups\/public\/<\/url>\
      <mirrorOf>central<\/mirrorOf>\
    <\/mirror>/' apache-maven-3.6.0/conf/settings.xml
fi
if [ ! -d BuildData ]; then git clone https://hub.spigotmc.org/stash/scm/spigot/builddata.git BuildData; fi;
if [ ! -d Bukkit ]; then git clone https://hub.spigotmc.org/stash/scm/spigot/bukkit.git Bukkit; fi;
if [ ! -d CraftBukkit ]; then git clone https://hub.spigotmc.org/stash/scm/spigot/craftbukkit.git CraftBukkit; fi;
if [ ! -d Spigot ]; then git clone https://hub.spigotmc.org/stash/scm/spigot/spigot.git Spigot; fi;

# 检测java版本
JvmPath=`${InstallPath}/tools/JvmCheck.sh -a build -v $VERSION`
# 构建(构建要求必须由完全符合的jvm版本运行,不允许"勉强". 以免因为版本不符出现偏差)
if [ $? == 0 ]; then
  $JvmPath -jar BuildTools.jar -rev $VERSION --compile ${COMPILE}
  mv /tmp/buildtools/${COMPILE}-$VERSION.jar $work_dir/
  exit 0
else
  exit 1
fi;

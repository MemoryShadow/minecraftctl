#!/bin/bash
###
 # @Date: 2022-07-06 11:11:33
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-24 12:24:06
 # @Description: Auto install minecraft server on linux
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

# List of projects supported for installation
AllowDownloadItems=(
  "vanilla"
  "mohist"
  "paper"
  "purpur"
  "cat"
  "tuinity"
  "authlib-injector"
)

#* show this help menu
function helpMenu() {
  echo -e "Auto install minecraft server on linux"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  echo -e "Usage: ${0} -i <item:vanilla [-f]> -v <version> [-h [mini]] [-ai]"
  echo -e "  -a,\t--authlib-injector\n\t\t\tAdditional installation of \e[33;48mauthlib-injector\e[0m when installing the specified server"
  echo -e "  -i,\t--item\t\tThe entry to be retrieved, the allowed values are as follows:\n\t\t\t vanilla, mohist, purpur, paper, spigot, bukkit, authlib-injector"
  echo -e "  \t\t\t \e[33;48mvanilla\e[0m: Vanilla minecraft server, install forge with the \e[1;32m-f\e[0m parameter"
  echo -e "  -v,\t--version\tThe version of the game to retrieve, defaults to the latest if left blank"
  echo -e "  -h,\t--help\t\tGet this help menu"
}

ARGS=`getopt -o afi:v:h:: -l authlib-injector,forge,item:,version:,help:: -- "$@"`
if [ $? != 0 ]; then
  helpMenu > /dev/stderr;exit 1;
fi

# Assign normalized command line arguments to positional arguments($1,$2,...)
eval set -- "${ARGS}"

AUTHLIBINJECTOR=false
FORGE=false
ITEM=''
VERSION='latest'

while true
do
  case "$1" in
    -a|--authlib-injector)
      AUTHLIBINJECTOR=true
      shift
      ;;
    -f|--forge)
      FORGE=true
      shift
      ;;
    -i|--item)
      ITEM="$2";
      shift 2
      ;;
    -v|--version)
      VERSION="$2";
      shift 2
      ;;
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

if [[ -z "${ITEM}" || -z "${AllowDownloadItems[$ITEM]}" ]]; then echo -e "The parameter does not exist or the item is unknown, please pass in the item to be executed\n" > /dev/stderr; helpMenu > /dev/stderr; exit 1; fi;

ITEMCheck=false
# 检查ITEM是否在AllowDownloadItems中
for Item in ${AllowDownloadItems[@]}
do
  if [ "${Item}" == "${ITEM}" ]; then
    ITEMCheck=true
    break
  fi
done
if [ $ITEMCheck == false ]; then echo -e "The item is not supported, please set a valid value for item\n" > /dev/stderr; helpMenu > /dev/stderr; exit 127; fi

unset ITEMCheck

# 根据指定目标下载对应的项目
DLPara=`bash /opt/minecraftctl/tools/Download/LinkGet.sh -i "${ITEM}" -v "${VERSION}"`
bash /opt/minecraftctl/tools/download.sh $DLPara

# 对vanilla做特殊处理，当ITEM为vanilla时，才会自动为此版本安装forge
if [[ "${ITEM}" == "vanilla" && ${FORGE} == true ]]; then 
  mv server.jar minecraft_server.$VERSION.jar
  mkdir -p ./libraries/net/minecraft/server/$VERSION/
  ln minecraft_server.$VERSION.jar ./libraries/net/minecraft/server/$VERSION/server-$VERSION.jar
  DLPara=`bash /opt/minecraftctl/tools/Download/LinkGet.sh -i forge -v ${VERSION}`
  bash /opt/minecraftctl/tools/download.sh $DLPara -o forge-$VERSION.jar
  JvmPath=`bash /opt/minecraftctl/tools/JvmCheck.sh -a build -v ${VERSION}`
  echo ${JvmPath}
  $JvmPath -jar forge-$VERSION.jar --installServer
  if [ -f ./run.sh ]; then
    sed -i "s/java/${JvmPath//\//\\/}/" ./run.sh
  fi
  unset DLPara JvmPath
  # 回过头来检查一次日志，如果有下载错误的苦就使用加速进行下载修补，
  rm forge-$VERSION.jar forge-$VERSION.jar.log
fi

# 安装authlib-injector
if [ ${AUTHLIBINJECTOR} == true ]; then 
  DLPara=`bash /opt/minecraftctl/tools/Download/LinkGet.sh -i authlib-injector -v ${VERSION}`
  bash /opt/minecraftctl/tools/download.sh $DLPara
  unset DLPara
fi
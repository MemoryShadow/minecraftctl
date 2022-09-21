#!/bin/bash
###
 # @Date: 2022-07-06 11:11:33
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-09-21 22:59:19
 # @Description: Auto install minecraft server on linux
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

cd $WorkDir

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
  GetI18nText Help_module_Introduction "Auto install minecraft server on linux"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl install -i <item:vanilla [-f]> [-v <version>] [-h [mini]] [-ai]"
  GetI18nText Help_module_content "  -a,\t--authlib-injector\n\t\t\tAdditional installation of \e[33;48mauthlib-injector\e[0m when installing the specified server\
\n  -i,\t--item\t\tThe entry to be retrieved, the allowed values are as follows:\n\t\t\t vanilla, mohist, purpur, paper, spigot, bukkit, authlib-injector\
\n  \t\t\t \e[33;48mvanilla\e[0m: Vanilla minecraft server, install forge with the \e[1;32m-f\e[0m parameter\
\n  -v,\t--version\tThe version of the game to retrieve, defaults to the latest if left blank\
\n  -h,\t--help\t\tGet this help menu"
  return 0;
}

ARGS=`getopt -o acfi:v:h:: -l authlib-injector,config,forge,item:,version:,help:: -- "$@"`
if [ $? != 0 ]; then
  helpMenu > /dev/stderr;exit 1;
fi

# Assign normalized command line arguments to positional arguments($1,$2,...)
eval set -- "${ARGS}"

AUTHLIBINJECTOR=false
CONFIG=false
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
    -c|--config)
      CONFIG=true
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

if [[ -z "${ITEM}" || -z "${AllowDownloadItems[$ITEM]}" ]]; then GetI18nText Error_Missing_parameters_item "The parameter does not exist or the item is unknown, please pass in the item to be executed\n" > /dev/stderr; helpMenu > /dev/stderr; exit 1; fi;

# 当版本为latest时,尝试获取最新版本号
if [[ "${VERSION}" == "latest" ]]; then
  VERSION=`curl -s "https://papermc.io/api/v2/projects/paper"`;VERSION=${VERSION##*,\"};VERSION=${VERSION%%\"*}
fi

# 检查ITEM是否在AllowDownloadItems中
ITEMCheck=false
for Item in ${AllowDownloadItems[@]}
do
  if [ "${Item}" == "${ITEM}" ]; then
    ITEMCheck=true
    break
  fi
done
if [ $ITEMCheck == false ]; then GetI18nText Error_Not_Supported_item "The item is not supported, please set a valid value for item\n" > /dev/stderr; helpMenu > /dev/stderr; exit 127; fi

unset ITEMCheck

# 根据指定目标下载对应的项目
DLPara=`bash ${InstallPath}/tools/Download/LinkGet.sh -i "${ITEM}" -v "${VERSION}"`
echo $DLPara

if [ ${ITEM} != "authlib-injector" ]; then
  # 如果不是指定安装authlib-injector, 就自定义输出文件名
  DLPara="$DLPara --output=${ITEM}-${VERSION}.jar"
fi
minecraftctl download $DLPara

# 对vanilla做特殊处理，当ITEM为vanilla时，才会自动为此版本安装forge
if [[ "${ITEM}" == "vanilla" && ${FORGE} == true ]]; then 
  mv server.jar minecraft_server.$VERSION.jar
  mkdir -p ./libraries/net/minecraft/server/$VERSION/
  ln minecraft_server.$VERSION.jar ./libraries/net/minecraft/server/$VERSION/server-$VERSION.jar
  DLPara=`bash ${InstallPath}/tools/Download/LinkGet.sh -i forge -v ${VERSION}`
  minecraftctl download $DLPara -o forge-$VERSION.jar
  JvmPath=`bash ${InstallPath}/tools/JvmCheck.sh -a build -v ${VERSION}`
  echo ${JvmPath}
  $JvmPath -jar forge-$VERSION.jar --installServer
  if [ -e ./run.sh ]; then
    sed -i "s/java/${JvmPath//\//\\/}/" ./run.sh
  fi
  unset DLPara
  # 回过头来检查一次日志，如果有下载错误的苦就使用加速进行下载修补，
  rm forge-$VERSION.jar forge-$VERSION.jar.log
fi

# 安装authlib-injector
if [ ${AUTHLIBINJECTOR} == true ]; then 
  DLPara=`bash ${InstallPath}/tools/Download/LinkGet.sh -i authlib-injector`
  minecraftctl download $DLPara
  unset DLPara
fi

# 生成配置文件信息
if [ ${CONFIG} == true ]; then
  echo -e "Generating configuration file..."
  if [ -z ${JvmPath} ]; then 
      JvmPath=`bash ${InstallPath}/tools/JvmCheck.sh -a run -v ${VERSION}`
  fi
  cat<<EOF>minecraftctl.conf
export ScreenName='Minecraft[${VERSION}] Java'
export JvmPath='${JvmPath}'
export MainJAR='${ITEM}-${VERSION}'
export ServerCore='${ITEM}'
EOF
  if [ ${AUTHLIBINJECTOR} == true ]; then 
    AIVer=`ls authlib-injector*`;AIVer=${AIVer##*-};AIVer=${AIVer%.*};
    echo -e "export Authlib=true\nexport AuthlibInjectorVer='${AIVer}'" >> minecraftctl.conf
  fi
fi

exit 0
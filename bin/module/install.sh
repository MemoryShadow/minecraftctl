#!/bin/bash
###
 # @Date: 2022-07-06 11:11:33
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-09-10 14:19:44
 # @Description: Auto install minecraft server on linux
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh;

cd $WorkDir;

# List of projects supported for installation
declare -A AllowInstallItems=(
  ['vanilla']='download'
  ['mohist']='download'
  ['paper']='download'
  ['purpur']='download'
  ['cat']='download'
  ['tuinity']='download'
  ['authlib-injector']='download'
  ['spigot']='build'
  ['craftbukkit']='build'
)

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "Auto install minecraft server on linux";
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl install -i <item:vanilla [-f]> [-v <version>] [-c] [-h [mini]] [-ai]";
  GetI18nText Help_module_content "  -m,\t--runname\tRun mode Settings, the default is MinecraftServer(V). Other allowed values are: EventExpansion(E), ModuleExpansion(M)\
\n  -a,\t--authlib-injector\n\t\t\tAdditional installation of \e[33;48mauthlib-injector\e[0m when installing the specified server\
\n  -i,\t--item\t\tThe entry to be retrieved, the allowed values are as follows:\n\t\t\t vanilla, mohist, purpur, paper, spigot, craftbukkit, authlib-injector\
\n  \t\t\t \e[33;48mvanilla\e[0m: Vanilla minecraft server, install forge with the \e[1;32m-f\e[0m parameter\
\n  \t\t\tWhen the RunName argument is not V, this argument allows you to specify an extension to install it on minecraftctl\
\n  -v,\t--version\tThe version of the game to retrieve, defaults to the latest if left blank\
\n  -c,\t--config\tAutomatically create configuration files\
\n  -h,\t--help\t\tGet this help menu";
  return 0;
}

ARGS=`getopt -o acfm:i:v:h:: -l authlib-injector,config,forge,runmode:,item:,version:,help:: -- "$@"`;
if [ $? != 0 ]; then
  helpMenu > /dev/stderr;exit 1;
fi

# Assign normalized command line arguments to positional arguments($1,$2,...)
eval set -- "${ARGS}";

AUTHLIBINJECTOR=false;
CONFIG=false;
FORGE=false;
ITEM='';
VERSION='latest';

# 运行模式的设置, 默认是 MinecraftServer(V). 允许的其他值为: EventExpansion(E), ModuleExpansion(M)
RUNMODE='MinecraftServer';

while true; do
  case "$1" in
    -a|--authlib-injector)
      AUTHLIBINJECTOR=true;
      shift;
      ;;
    -c|--config)
      CONFIG=true;
      shift;
      ;;
    -f|--forge)
      FORGE=true;
      shift;
      ;;
    -i|--item)
      ITEM="$2";
      shift 2;
      ;;
    -m|--runmode)
      RUNMODE="$2";
      # 在这里进行翻译
      case "$2" in
      V|MinecraftServer)
        RUNMODE="MinecraftServer";
        ;;
      E|EventExpansion)
        RUNMODE="EventExpansion";
        ;;
      M|ModuleExpansion)
        RUNMODE="ModuleExpansion";
        ;;
      *)
        GetI18nText Error_Internal "Internal error!" > /dev/stderr;
        exit 1;
        ;;
      esac
      shift 2;
      ;;
    -v|--version)
      VERSION="$2";
      shift 2;
      ;;
    -h|--help)
      helpMenu "$2";
      exit $?;
      ;;
    --)
      shift;
      break;
      ;;
    *)
      GetI18nText Error_Internal "Internal error!" > /dev/stderr;
      exit 1;
      ;;
  esac
done

if [[ -z "${ITEM}" ]] ; then GetI18nText Error_Missing_parameters_item "The parameter does not exist or the item is unknown, please pass in the item to be executed\n" > /dev/stderr; helpMenu > /dev/stderr; exit 1; fi;

case "$RUNMODE" in
MinecraftServer)
  # 如果ITEM没有, 或者AllowInstallItems没有, 则报错
  if [[ -z ${AllowInstallItems[$ITEM]} ]]; then GetI18nText Error_Missing_parameters_item "The parameter does not exist or the item is unknown, please pass in the item to be executed\n" > /dev/stderr; helpMenu > /dev/stderr; exit 1; fi;

  # 当版本为latest时,尝试获取最新版本号
  if [[ "${VERSION}" == "latest" ]]; then
    VERSION=`curl -s "https://papermc.io/api/v2/projects/paper"`;VERSION=${VERSION##*,\"};VERSION=${VERSION%%\"*};
  fi

  # 检查ITEM是否在AllowDownloadItems中
  # 如果不在, 就说明是需要自己构建的项目
  if [ "${AllowInstallItems[$ITEM]}" == "build" ]; then 
    # 调用构建工具
    ${InstallPath}/tools/Download/build.sh -v ${VERSION} -c ${ITEM};
  elif [ "${AllowInstallItems[$ITEM]}" == "download" ]; then 
    # 根据指定目标下载对应的项目
    DLPara=`bash ${InstallPath}/tools/Download/LinkGet.sh -i "${ITEM}" -v "${VERSION}"`;
    MainJAR="${ITEM}-${VERSION}";
    ServerCore="${ITEM}";
    if [ ${ITEM} != "authlib-injector" ]; then
      # 如果不是指定安装authlib-injector, 就自定义输出文件名
      DLPara="$DLPara --output=${ITEM}-${VERSION}.jar";
    fi
    minecraftctl download $DLPara;
  fi

  # 对vanilla做特殊处理，当ITEM为vanilla时，才会自动为此版本安装forge
  if [[ "${ITEM}" == "vanilla" && ${FORGE} == true ]]; then 
    mv vanilla-$VERSION.jar minecraft_server.$VERSION.jar;
    mkdir -p ./libraries/net/minecraft/server/$VERSION/;
    ln minecraft_server.$VERSION.jar ./libraries/net/minecraft/server/$VERSION/server-$VERSION.jar;
    DLPara=`bash ${InstallPath}/tools/Download/LinkGet.sh -i forge -v ${VERSION}`;
    minecraftctl download $DLPara -o forge-$VERSION.jar;
    # 获取构建使用的jvm路径
    BuildJvmPath=`bash ${InstallPath}/tools/JvmCheck.sh -a build -v ${VERSION}`;
    echo ${BuildJvmPath};
    $BuildJvmPath -jar forge-$VERSION.jar --installServer;
    if [ -e ./run.sh ]; then
      sed -i "s/java/${JvmPath//\//\\/}/" ./run.sh;
    fi
    unset DLPara
    # TODO 回过头来检查一次日志，如果有下载错误的话就使用加速进行下载修补
    rm forge-$VERSION.jar forge-$VERSION.jar.log
    # 更新入口JAR的名字
    MainJAR=`ls forge-$VERSION-*.jar`; MainJAR=${MainJAR%.*};
    ServerCore="forge"
  fi

  # 安装authlib-injector
  if [ ${AUTHLIBINJECTOR} == true ]; then 
    DLPara=`bash ${InstallPath}/tools/Download/LinkGet.sh -i authlib-injector`
    minecraftctl download $DLPara
    unset DLPara
  fi

  # 生成配置文件信息
  if [ ${CONFIG} == true ]; then
    GetI18nText Info_GeneratingConfigurationFile "Generating configuration file..."
    # 如果BuildJvmPath被在上面生成过了, 就不再重新生成一次
    if [ ! -z ${BuildJvmPath} ]; then
      JvmPath=${BuildJvmPath}
    else
      JvmPath=`bash ${InstallPath}/tools/JvmCheck.sh -a run -v ${VERSION}`
    fi
    cat<<EOF>minecraftctl.conf
export ScreenName='Minecraft[${VERSION}] Java'
export JvmPath='${JvmPath}'
export MainJAR='${MainJAR}'
export StartCache='${StartCache}'
export MaxCache='${MaxCache}'
export UserExtraParameters="-XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:-OmitStackTraceInFastThrow -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=8 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=true -Daikars.new.flags=true"
export ServerCore='${ServerCore}'
EOF
    if [ ${AUTHLIBINJECTOR} == true ]; then 
      AIVer=`ls authlib-injector*`;AIVer=${AIVer##*-};AIVer=${AIVer%.*};
      echo -e "export Authlib=true\nexport AuthlibInjectorVer='${AIVer}'" >> minecraftctl.conf;
    fi
  fi
  ;;

EventExpansion)
  TmpInstallExpansion='/tmp/minecraftctl/install/Expansion/';
  mkdir -p "${TmpInstallExpansion}";
  # 第一步, 确认使用的格式. 允许的格式为: 一个仓库URL, 一个zip压缩包, 一个直接的名字(后续支持, 默认值)
  # 使用-i来指定需要安装的目标.
  declare -A TargetTypes=(
    # 认为是一个仓库链接
    ['GitUrl']='^https?://.*\.git$'
    # 认为这是一个本地路径
    ['ZIPPath']='^(?!.*://).*\.zip$'
  )

  for TargetType in "${!TargetTypes[@]}"; do
    grep -iqP "${TargetTypes[$TargetType]}" <<< "${ITEM}";
    if [ $? -eq 0 ]; then
      RepoName=${ITEM%.*}; RepoName=${RepoName##*/};
      TmpInstallExpansionRepo="${TmpInstallExpansion}/${RepoName}";
      case "$TargetType" in
      GitUrl)
        # 如果已经存在同名git仓库就从clone改为pull
        if [ -d "${TmpInstallExpansionRepo}/.git" ]; then
          WD=${PWD};
          cd "${TmpInstallExpansionRepo}";
          git checkout .;
          git pull -f;
          if [ $? != 0 ]; then GetI18nText Error_Internal "Internal error!" > /dev/stderr; exit 1; fi
          cd "${WD}";
          unset WD;
        else
          if [ -d "${TmpInstallExpansionRepo}" ]; then sudo rm -rf "${TmpInstallExpansionRepo}"; fi;
          git clone --depth 1 "${ITEM}" "${TmpInstallExpansionRepo}";
          if [ $? != 0 ]; then GetI18nText Error_Internal "Internal error!" > /dev/stderr; exit 1; fi
        fi
        ;;
      ZIPPath)
        if [ -d "${TmpInstallExpansionRepo}" ]; then sudo rm -rf "${TmpInstallExpansionRepo}/*"; fi;
        mkdir -p "${TmpInstallExpansionRepo}";
        unzip -o "${ITEM}" -d "${TmpInstallExpansionRepo}";
        if [ $? != 0 ]; then GetI18nText Error_Internal "Internal error!" > /dev/stderr; exit 1; fi
        ;;
      esac
    fi
  done

  # TODO 这两个都无法识别的情况下, 认为这是一个默认的名字, 前往仓库去寻找(索引仓库等待建立)
  if [ -z $RepoName ]; then
    RepoName="${ITEM}";
    TmpInstallExpansionRepo="${TmpInstallExpansion}/${RepoName}";
    echo "暂未开放此类型 ${RUNMODE}";
    exit 0;
  fi

  # 将已经准备好的目录结构装入目录
  ExpansionStructure=`find "${TmpInstallExpansionRepo}" -mindepth 2 -maxdepth 2 -type d -not -path "${TmpInstallExpansionRepo}/.*" | sed "s#^${TmpInstallExpansionRepo}/##"`;
  for ExpansionStructure_Item in ${ExpansionStructure[@]}; do
    EventDivide=${ExpansionStructure_Item%/*};
    EventType=${ExpansionStructure_Item##*/}; EventType=${EventType%.*};
    # 当目标事件分类与事件类型存在时, 将这些子脚本复制进工作目录
    if [[ -d "/opt/minecraftctl/event/${EventDivide}" && -s "/opt/minecraftctl/event/${EventDivide}/${EventType}" ]]; then
      sudo cp -rf ${TmpInstallExpansionRepo}/${EventDivide}/${EventType}.d/* "/opt/minecraftctl/event/${EventDivide}/${EventType}.d/"
    fi
  done
  ;;

ModuleExpansion)
  echo "暂未开放";
  ;;
esac

exit 0
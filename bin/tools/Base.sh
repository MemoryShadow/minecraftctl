#!/bin/bash
###
 # @Date: 2022-07-24 12:35:58
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-01-22 23:08:30
 # @Description: 为其他函数提供基本的函数库与初始加载
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

export TIME_STYLE='+%Y-%m-%d %H:%M:%S'

if [ -e ${GamePath}/minecraftctl.conf ]; then
  source ${GamePath}/minecraftctl.conf
fi

# 加载局部配置覆盖全局配置, 当前目录中的minecraftctl.conf文件优先级最高
if [ -e $WorkDir/minecraftctl.conf ]; then
  source $WorkDir/minecraftctl.conf
  # 当检测到当前工作目录为游戏目录时, 将游戏目录设置为当前工作目录
  GamePath=$WorkDir
else
  if [ -e ${GamePath}/minecraftctl.conf ]; then
    source ${GamePath}/minecraftctl.conf
  fi
  # 如果工作目录没有配置,就前往配置中的目录
  if [ ! -d ${GamePath} ]; then
    mkdir -p ${GamePath}
  fi
fi
cd ${GamePath}

# i18n文件内容缓存
declare -A I18n_Cache=()

#*预处理i18n文件, 避免频繁读盘
# 语言不为default并且在本地存在的情况下才预加载
if [[ "${Language}" != "default" && -e "/etc/minecraftctl/i18n/${Language}.lang" ]]; then
  # 检查是否是在引导文件中发起的请求
  grep -qe "/minecraftctl$" <<< "$0"
  # 如果不是在引导文件里, 就检查查询来源以匹配多语言文件(不存在对应语言的文件就放弃查找, 因为此时主文件应该是已经加载过了)
  if [[ $? != 0 && -e "/etc/minecraftctl/i18n/${Language}/${0/$InstallPath/}.lang" ]]; then 
    while read -r line || [[ -n ${line} ]]; do
      I18n_Cache[${line%%:*}]=${line#*:}
    done <"/etc/minecraftctl/i18n/${Language}${0/$InstallPath/}.lang"
  else
    # 先去读公共i18n文件
    while read -r line || [[ -n ${line} ]]; do
      I18n_Cache[${line%:*}]=${line#*:}
    done <"/etc/minecraftctl/i18n/${Language}.lang"
  fi
fi


# 通过echo返回一个字符串, 通过返回值返回是否成功
# 参数1(必须): 请求的字段编号
# 参数2(必须): 当没有这个资源的时候应该显示的字符串
# 参数3(可选): 需要被格式化输出的内容, 参数会被直接提交给printf进行处理
function GetI18nText() {
  if [ -z "${I18n_Cache[$1]}" ]; then
    printf "$2\n"; "$@"
    return 1;
  else
    Text=$1
    shift 2
    printf "${I18n_Cache["${Text}"]}\n" "$@"
    return 0;
  fi
}

# 返回服务器核心版本,0表示配置错误,1表示官方核心,2表示非官方核心
function GetServerCoreVersion() {
  case ${ServerCore} in
  official | vanilla | mohist | forge)
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
  grep -q "${ScreenName//[/\\[}" < <(screen -ls)
}

# 向服务器发送命令
#?参数1: 要发送的命令
#?参数2: 要发送到的窗口终端(默认值为0)
function cmd2server() {
  if [ "$1" != "" ]; then
  # 分批推送, 按照长度分批
  local BatchNum=499
  local CmdLen=`awk '{print length($0)}' <<< "${1}"`
  local CmdBatchNum=$[CmdLen/BatchNum]
  for((batch=0; batch <= CmdBatchNum; batch++)); do
    local CmdBatch=`awk "{print substr(\\\$0,${batch}*${BatchNum}+1,(${batch}+1)*${BatchNum})}" <<< "${1}"`
    screen -x -S "$ScreenName" -p ${2:-0} -X stuff "${CmdBatch}"
  done
  unset batch
  screen -x -S "$ScreenName" -p ${2:-0} -X stuff "\n"
  fi
  return 0
}

#!/bin/bash
###
 # @Date: 2022-07-24 14:55:37
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-09-22 09:48:19
 # @Description: 编辑文件
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

cd $WorkDir

# 在编辑器中打开指定的文件
function openEditer() {
  # 检测当前是否在VSCode中打开
  whereis code | grep :\ / >/dev/null
  if [ $? -eq 0 ]; then
    code $1
  else
    # 尝试自动解决中文乱码的问题
    if [ ! -e ~/.vimrc ]; then
      echo "set enc=utf8">~/.vimrc
    fi
    vim $1
  fi
}

# 编辑配置文件
function EditConfig() {
  if [ ! -z $1 ]; then
    local filePath=""
    case $1 in
    cfg | conf | config)
      # 编辑配置文件, 检测已有的文件(当前文件夹文件->游戏目录中的文件->全局文件)
      # 其中, 游戏目录有可能与当前文件夹文件重复, 会在Base中被初始化
      if [ -e "${GamePath}/minecraftctl.conf" ]; then
        filePath="${GamePath}/minecraftctl.conf"
      else
        filePath="/etc/minecraftctl/config"
      fi
    ;;
    *)
      return 1
      ;;
    esac
    openEditer $filePath
  fi
}

# 编辑模块文件
function EditModuleFile(){
  local completions=`find "$InstallPath/module/" -name "*.sh" -exec basename {} \;`;
  local COMPREPLY=(`compgen -W "$completions" "${1:-ed}"`);
  openEditer "$InstallPath/module/${COMPREPLY}";
  return 0;
}

# 编辑服务器配置文件
function EditServerConfigFile(){
  # 按照这个顺序查找对应的文件
  declare -A SearchOrder=(
    ['.']=1
    ['config']=1
  )
  for dir in ${!SearchOrder[@]}; do
    # 检查此目录是否存在, 不存在就跳过
    if [ ! -d "${GamePath}/${dir}" ]; then continue; fi
    # 列出目录下的配置文件
    local completions=`find "${GamePath}/${dir}/" -maxdepth ${SearchOrder[${dir}]} -regextype posix-extended -regex ".*\.(json|conf|yml|txt|properties)$" -exec basename {} \;`;
    # 匹配文件名
    local COMPREPLY=(`compgen -W "$completions" "${1:-config}"`);
    if [ ! -z ${COMPREPLY} ]; then
      openEditer "${GamePath}/${dir}/${COMPREPLY}"
    fi
  done
  return 0;
}

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "Edit minecraftctl and minecraft related files"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl edit [-m ModuleName] -[s serverfile] [-h[mini]]\n"
  GetI18nText Help_module_content "  -m,\t--module\t\tSpecify the module name to edit\n  -s,\t--server\t\tSpecifies the server filename to edit, The search order is: server root directory, config"
  return 0;
}

ARGS=`getopt -o m:s:h:: -l module:,server:,help:: -- "$@"`
if [ $? != 0 ]; then
  helpMenu > /dev/stderr;exit 1;
fi

# Assign normalized command line arguments to positional arguments($1,$2,...)
eval set -- "${ARGS}"

while true
do
  case "$1" in
    -h|--help)
      helpMenu "$2"
      exit $?
      ;;
    -m|--module)
      EditModuleFile "$2"
      exit $?
      ;;
    -s|--server)
      EditServerConfigFile "$2"
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

if [ -z $1 ]; then
  openEditer "$InstallPath/minecraftctl"
else
  EditConfig $1
fi
#!/bin/bash
###
 # @Date: 2022-07-24 15:05:22
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-01-17 20:15:53
 # @Description: 获取当前软件的帮助菜单
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

#* show this help menu
function _helpMenu() {
  if [[ ! -z $1 && "$1" == "mini" ]]; then GetI18nText Help_minecraftctl_mini "Get this help menu"; return 0; fi
  GetI18nText Help_minecraftctl "This script is used to control the Minecraft server in the simplest possible way"
  GetI18nText Help_usage "minecraftctl <module name> [module parameters]\n"
  local ModuleList=`ls ${InstallPath}/module/`
  ModuleList=(${ModuleList// /})
  local Module=''
  for Module in "${ModuleList[@]}"
  do
    Module=${Module%.*}
    local Separate=
    if [ "${#Module}" -gt 7 ]; then Separate="\n\t\t"; 
    elif [ "${#Module}" -lt 4 ]; then Separate="  \t\t";
    else Separate="  \t"; 
    fi
    local ModuleMiniHelp=`minecraftctl ${Module} -hmini`
    echo -e "  ${Module}${Separate}${ModuleMiniHelp}"
  done
  return 0;
}

ARGS=`getopt -o h:: -l help:: -- "$@"`
if [ $? != 0 ]; then
  helpMenu > /dev/stderr;exit 1;
fi

# Assign normalized command line arguments to positional arguments($1,$2,...)
eval set -- "${ARGS}"

while true
do
  case "$1" in
    -h|--help)
      _helpMenu "$2"
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

_helpMenu "$2"
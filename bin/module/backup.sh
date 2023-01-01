#!/bin/bash
###
 # @Date: 2022-07-24 14:01:03
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-01-01 17:26:58
 # @Description: 备份服务器
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

BACKUPNAME=''

# 备份服务器存档
function Backup() {
  # 进行基本的配置
  local BackupDir="Backup"
  local BackupConfigDir="$BackupDir/Config"

  if [ -d "$BackupDir" ]; then
    if [ -d "$BackupDir/world" ]; then
      # 如果备份数据存在,就将其删除
      rm -rf "$BackupDir/world"
    fi
    cp -r "world" "$BackupDir/world"

    # 官方版本备份完成, 检测是否为非官方版本, 如果是, 则进行非官方版本备份
    GetServerCoreVersion
    if [ "$?" == "2" ]; then
      cp -r "world_nether" "$BackupDir/world/DIM-1"
      cp -r "world_the_end" "$BackupDir/world/DIM1"
    fi
    # 备份配置文件
    if [ -d "Backup/Config" ]; then
      if [ -e "Backup/Config/server.properties" ]; then
        rm -rf "Backup/Config/server.properties"
      fi
      cp "server.properties" "Backup/Config/server.properties"
      if [ -e "Backup/Config/ops.json" ]; then
        rm -rf "Backup/Config/ops.json"
      fi
      cp "ops.json" "Backup/Config/ops.json"
      if [ -e "Backup/Config/config" ]; then
        rm -rf "Backup/Config/config"
      fi
      cp "/etc/minecraftctl/config" "Backup/Config/config"
      if [ -e "Backup/Config/minecraftctl.conf" ]; then
        rm -rf "Backup/Config/minecraftctl.conf"
      fi
      cp "minecraftctl.conf" "Backup/Config/minecraftctl.conf"
    fi
    # 迁移跑图区块
    #if [ -d "Backup/mcaFile" ]; then
    # 如果文件夹存在，就开始迁移
    # 迁移主世界区块文件
    #if [ ! -d "Backup/mcaFile/master" ]; then mkdir ./Backup/mcaFile/master/ fi;
    #find ./world/region/ -size 12288c -exec mv -f {} ./Backup/mcaFile/master/ \;
    #fi

    date

    GetI18nText Info_BackupFinish_archiveing "The backup is complete, archiving (you can put it in the background to run by yourself during archiving)..."
    # 移出备份存档
    if [ -e "Backup/Backup.tar.xz" ]; then
      mv "Backup/Backup.tar.xz" ./
    fi
    mv Backup/Backup*.tar.xz ./ 2>/dev/null
    # 将备份好的文件进行压缩(默认使用稳妥的1线程和6的压缩比率)
    if [ ! -z ${BACKUPNAME} ]; then
      BACKUPNAME="-$BACKUPNAME"
    fi
    if [[ ${BackupThread} == 1 ]] && [[ ${BackupCompressLevel} == 6 ]]; then 
      tar -Jcf "Backup${BACKUPNAME}.tar.xz" Backup/*
    else
      XZ_OPT="-${BackupCompressLevel}T ${BackupThread}" tar -cJf "Backup${BACKUPNAME}.tar.xz" Backup/* 
    fi
    # 删除多余的备份文件
    rm -rf Backup/world* Backup/Config/*
    # 移回备份存档
    mv Backup*.tar.xz Backup/ 2>/dev/null
  else
    GetI18nText Info_NotFoundBackupDir "Backup folder not found, if you want to backup, you need to create this folder, if you want to backup configuration files, you need to create Backup/Config folder."; > /dev/stderr
  fi

  date
  GetI18nText Info_CompleteOperation "Complete the operation."
}

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "Backup the server archive (if the server is running, an emergency backup is made)"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl backup [-n BackupName] [-h[mini]]\n"
  GetI18nText Help_module_content "  -n,\t--backupname\tthe name of the backup\n  -h,\t--help\t\tGet this help menu"
  return 0;
}

ARGS=`getopt -o n:h:: -l name:,help:: -- "$@"`
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
    -n|--name)
      BACKUPNAME="$2"
      shift 2
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

date
Info_AboutStartBacking=`GetI18nText Info_AboutStartBacking "About to start backing up the server"`
echo "${Info_AboutStartBacking}"
mkdir -p "Backup/Config"
minecraftctl say -m "${Info_AboutStartBacking}"
cmd2server 'save-all flush'
Backup
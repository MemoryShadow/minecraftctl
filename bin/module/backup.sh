#!/bin/bash
###
 # @Date: 2022-07-24 14:01:03
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-01-07 15:32:33
 # @Description: 备份服务器
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

BACKUPNAME=''
MODE='Backup'

function InitServerInfo() {
  # 备份目录
  BackupDir="Backup"
  # 配置文件备份目录
  BackupConfigDir="$BackupDir/Config"
  if [ -z "$BACKUPNAME" ]; then
    # 备份名称
    BackupName="(def)"
    # 备份文件名
    BackupFileName="${BackupDir}/Backup.tar.xz"
  else
    BackupName="${BACKUPNAME}"
    BackupFileName="${BackupDir}/Backup-${BACKUPNAME// /_}.tar.xz"
  fi
  # 服务器存档名
  LevelName=`grep -e '^level-name' server.properties | sed 's/^level-name=//'`
  # 备份文件存档名
  BackupLevelName='world'
  # 备份中下界存档位置
  BackupLevelNether="$BackupDir/${BackupLevelName}/DIM-1"
  # 备份中末地存档位置
  BackupLevelEnd="$BackupDir/${BackupLevelName}/DIM1"
  # 检查核心
  GetServerCoreVersion
  if [ "$?" == "2" ]; then
    LevelNether="${LevelName}_nether"
    LevelEnd="${LevelName}_the_end"
  elif [ "$?" == "1" ]; then
    # 存档中下界存档位置
    LevelNether="${LevelName}/DIM-1"
    # 存档中末地存档位置
    LevelEnd="${LevelName}/DIM1"
  fi
}

# 备份服务器存档
function Backup() {
  Info_AboutStartBacking=`GetI18nText Info_AboutStartBacking "About to start backing up the server"`
  echo "${Info_AboutStartBacking}"
  # 这里自动创建目录替代运维人员手动了
  mkdir -p "Backup/Config"
  ExistServerExample
  if [ $? -eq 0 ]; then
    minecraftctl say -m "${Info_AboutStartBacking}"
    cmd2server 'save-all flush'
  fi

  if [ -d "$BackupDir" ]; then
      # 如果备份数据存在,就将其删除
    if [ -d "$BackupDir/${BackupLevelName}" ]; then
      rm -rf "$BackupDir/${BackupLevelName}";
    fi
    # 备份各个维度的内容
    cp -r "${LevelName}" "$BackupDir/${BackupLevelName}"
    if [ ! -d "${BackupLevelNether}" ]; then
      cp -r "${LevelNether}" "${BackupLevelNether}";
    fi
    if [ ! -d "${BackupLevelEnd}" ]; then
      cp -r "${LevelEnd}" "${BackupLevelEnd}";
    fi

    # 备份配置文件
    if [ -d "${BackupConfigDir}" ]; then
      cp -lf "server.properties" "${BackupConfigDir}/server.properties"
      cp -lf "ops.json" "${BackupConfigDir}/ops.json"
      cp -lf "/etc/minecraftctl/config" "${BackupConfigDir}/config"
      cp -lf "minecraftctl.conf" "${BackupConfigDir}/minecraftctl.conf"
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
    mv Backup/Backup*.tar.xz ./ 2>/dev/null
    # 将备份好的文件进行压缩(默认使用稳妥的1线程和6的压缩比率)
    if [[ ${BackupThread} == 1 ]] && [[ ${BackupCompressLevel} == 6 ]]; then 
      tar -Jcf "${BackupFileName}" Backup/*
    else
      XZ_OPT="-${BackupCompressLevel}T ${BackupThread}" tar -cJf "${BackupFileName}" Backup/* 
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
  return 0
}

# 还原服务器存档
function Recover() {
  # 这里如果剩余空间不足可能会导致丢失数据
  # minecraftctl backup -n "revert"
  # 记录记录是否需要重新拉起服务
  RestartServer=false

  # 检查备份目录与备份的存档文件是否存在
  if [[ -d "$BackupDir" && -e "${BackupFileName}" ]]; then
    Info_AboutStartRecover=`GetI18nText Info_AboutStartRecover "The backup is about to be restored"`
    echo "${Info_AboutStartRecover}"
    ExistServerExample
    if [ $? -eq 0 ]; then
      RestartServer=true
      cmd2server 'save-all flush'
      minecraftctl stop "${Info_AboutStartRecover}"
    fi
    # 删除当前服务器的存档(这里提前删除是避免空间不足)
    if [ -d "${LevelName}" ]; then rm -rf "${LevelName}"; fi
    if [ -d "${LevelNether}" ]; then rm -rf "${LevelNether}"; fi
    if [ -d "${LevelEnd}" ]; then rm -rf "${LevelEnd}"; fi

    GetI18nText Info_unArchiveing "Decompressing the archive..."
    # 解压对应的文件
    tar -C . -xf "${BackupFileName}" "${BackupDir}/${BackupLevelName}"
    date
    # 恢复数据
    GetI18nText Info_RecoverDataing "Recovering data..."
    mv "${BackupDir}/${BackupLevelName}" "${LevelName}"
    if [ ! -d "${LevelNether}" ]; then mv "${BackupLevelNether}" "${LevelNether}"; fi
    if [ ! -d "${LevelEnd}" ]; then mv "${BackupLevelEnd}" "${LevelEnd}"; fi
    # 还原配置文件
    if [ -d "${BackupConfigDir}" ]; then
      if [ -e "${BackupConfigDir}/server.properties" ]; then
        mv -f "${BackupConfigDir}/server.properties" "server.properties"
      fi
      if [ -e "${BackupConfigDir}/ops.json" ]; then
        mv -f "${BackupConfigDir}/ops.json" "ops.json"
      fi
      if [ -e "${BackupConfigDir}/config" ]; then
        mv -f "${BackupConfigDir}/config" "/etc/minecraftctl/config";
      fi
      if [ -e "${BackupConfigDir}/minecraftctl.conf" ]; then
        mv -f "${BackupConfigDir}/minecraftctl.conf" "minecraftctl.conf"
      fi
    fi
    # 迁移跑图区块
    #if [ -d "Backup/mcaFile" ]; then
    # 如果文件夹存在，就开始迁移
    # 迁移主世界区块文件
    #if [ ! -d "Backup/mcaFile/master" ]; then mkdir ./Backup/mcaFile/master/ fi;
    #find ./world/region/ -size 12288c -exec mv -f {} ./Backup/mcaFile/master/ \;
    #fi
    date
  else
    GetI18nText Info_NotFoundBackupFileORDir "The Backup folder is not found or the corresponding backup is not found. Please enter the correct name. If there is a space in the name, please wrap it in double quotation marks."; > /dev/stderr
    return 1
  fi
  GetI18nText Info_CompleteOperation "Complete the operation."
  if [ "$RestartServer" == "true" ]; then minecraftctl start; fi
  return 0
}

# 列出可还原的备份列表(按最近修改时间排序)
function BackupList() {
  Info_BackupListTitle=`GetI18nText Info_BackupListTitle "name\tcreate time\tfile size"`
  ls -lqth Backup/Backup*.tar.xz 2>/dev/null | awk -F ' '\
  "BEGIN{print \"$Info_BackupListTitle\"}\
  {\
    gsub(/^Backup\/Backup-?|\.tar\.xz$/, \"\", \$9)\
    gsub(/_/, \" \", \$9);\
    if(\$9 == \"\") \$9=\"(def)\"\
  }\
  {print \$9\"\t\"\$6\$7\" \"\$8\"\t\"\$5};"
  return 0;
}

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "Back up or restore server archives"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl backup [-n BackupName] [-h[mini]|r|l]\n"
  GetI18nText Help_module_content "  -n,\t--backupname\tthe name of the backup\n  -r,\t--recover\tChange mode to restore archive mode (service process will be restarted)\n  -l,\t--list\t\tList the backups that can be restored\n  -h,\t--help\t\tGet this help menu"
  return 0;
}

ARGS=`getopt -o n:lrh:: -l name:,list,recover,help:: -- "$@"`
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
    -l|--list)
      BackupList
      exit $?
      ;;
    -n|--name)
      BACKUPNAME="$2"
      shift 2
      ;;
    -r|--recover)
      MODE="Recover"
      shift
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
InitServerInfo
${MODE} "${BACKUPNAME}"
exit $?
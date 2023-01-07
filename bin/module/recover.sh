#!/bin/bash
###
 # @Date: 2022-07-24 14:01:03
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-01-07 12:40:55
 # @Description: 备份服务器
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

BACKUPNAME=''

# 还原服务器存档
function Recover() {
  # minecraftctl backup -n "revert"
  Info_AboutStartRecover=`GetI18nText Info_AboutStartRecover "The backup is about to be restored"`
  echo "${Info_AboutStartRecover}"
  ExistServerExample
  if [ $? -eq 0 ]; then
    minecraftctl say -m "${Info_AboutStartRecover}"
    cmd2server 'save-all flush'
    minecraftctl stop "服务器正在回档"
  fi
  # 进行基本的配置
  local BackupDir="Backup"
  local BackupConfigDir="$BackupDir/Config"
  # 将备份名转换为对应的文件名
  if [[ ! -z $1 ]]; then
    BackupFileName="Backup/Backup-${1// /_}.tar.xz"
  else
    BackupFileName="Backup/Backup.tar.xz"
  fi

  # 检查备份目录与备份的存档文件是否存在
  if [[ -d "$BackupDir" && -e "${BackupFileName}" ]]; then
    # 删除当前服务器的存档(这里提前删除是避免空间不足)
    if [ -d "world" ]; then rm -rf "world"; fi

    # 官方版本删除完成, 检测是否为非官方版本, 如果是, 则进行非官方版本数据删除
    GetServerCoreVersion
    if [ "$?" == "2" ]; then
      if [ -d "world_nether" ]; then rm -rf "world_nether"; fi
      if [ -d "world_the_end" ]; then rm -rf "world_the_end"; fi
    fi
    GetI18nText Info_unArchiveing "Decompressing the archive..."
    # 解压对应的文件
    tar -C . -xf "${BackupFileName}" "Backup/world"
    date
    # 恢复数据
    GetI18nText Info_RecoverDataing "Recovering data..."
    mv "$BackupDir/world" "world"
    GetServerCoreVersion
    if [ "$?" == "2" ]; then
      mv "world/DIM-1" "world_nether"
      mv "world/DIM1" "world_the_end"
    fi
    # 还原配置文件
    if [ -d "Backup/Config" ]; then
      if [ -e "Backup/Config/server.properties" ]; then
        mv -f "Backup/Config/server.properties" "server.properties"
      fi
      if [ -e "Backup/Config/ops.json" ]; then
        mv -f "Backup/Config/ops.json" "ops.json"
      fi
      if [ -e "Backup/Config/config" ]; then
        mv -f "Backup/Config/config" "/etc/minecraftctl/config";
      fi
      if [ -e "Backup/Config/minecraftctl.conf" ]; then
        mv -f "Backup/Config/minecraftctl.conf" "minecraftctl.conf"
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
  GetI18nText Help_module_Introduction "Immediately shut down the server, back up the current server information, and restore the server data from the previous backup archive"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl recover [-n BackupName] [--list] [-h[mini]]\n"
  GetI18nText Help_module_content "  -n,\t--backupname\tthe name of the backup\n  -l,\t--list\t\tList the backups that can be restored\n  -h,\t--help\t\tGet this help menu"
  return 0;
}

ARGS=`getopt -o n:lh:: -l name:,list,help:: -- "$@"`
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

Recover "${BACKUPNAME}"
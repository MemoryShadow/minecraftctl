#!/bin/bash
###
 # @Date: 2022-07-24 14:01:03
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-01-10 03:36:03
 # @Description: 备份服务器
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

BACKUPNAME=''
MODE='Backup'

# 生成归档文件
#?$1|必须: 指定需要归档的目录
#?$2|必须: 指定输出文件的文件名
function ArchiveBackup() {
    # 如果存在同名归档文件就删除
    if [ -e "${2}" ]; then
      rm -rf "${2}";
    fi
    # 移出备份存档
    mv Backup/Backup*.tar.xz ./ 2>/dev/null
    GetHashList "${1}/${BackupLevelName}" 'sha1'
    GetHashList "${1}/${BackupLevelName}" 'md5'
    mv sha1.csv "${1}/Hash/"
    mv md5.csv "${1}/Hash/"
    # 将备份好的文件进行压缩(默认使用稳妥的1线程和6的压缩比率)
    if [[ ${BackupThread} == 1 ]] && [[ ${BackupCompressLevel} == 6 ]]; then 
      tar -Jcf "${2}" ${1}/*
    else
      XZ_OPT="-${BackupCompressLevel}T ${BackupThread}" tar -cJf "${2}" ${1}/* 
    fi
    # 删除多余的备份文件
    rm -rf ${1}/world* ${1}/Config/* ${1}/Hash/*
    # 移回备份存档
    mv Backup*.tar.xz "${1}/" 2>/dev/null
}

# 获取指定文件或文件夹的指定Hash列表csv版本
#?$1|必须: 指定的目标, 可以为文件夹或者压缩文件, 当为文件夹时会生成此文件夹的hash列表, 当为压缩文件时会提取Hash目录下的内容
#?$2|必须: 指定的hash类型, 允许的值为: sha1, sha224, sha256, sha384, sha512, md5
#?$3|可选: $1为目录时生效, 指定的文件输出目录
# return: 
#   0: 完成任务
#   1: $1指定的文件或目录不存在
#   2: $1指定的文件中没有指定类型的hash表
function GetHashList(){
  # 允许的Hash类型, 写成数组是确保语义明确
  local AllowHashTypes=(sha1 sha224 sha256 sha384 sha512 md5)
  # 当前实例中的Hash类型
  local HashType=''
  # 初始化检测
  echo "${AllowHashTypes[@]}" | grep -qw "$2"
  if [ "$?" == "0" ]; then HashType="$2"; fi

  # 确认目标文件是存在的
  if [ -e "$1" ]; then
    # 如果是文件就提取这个文件
    if [ -f "$1" ]; then
      tar -C . -xf "$1" "${BackupDir}/Hash/${HashType}.csv" 2>/dev/null
      # 压缩包中找不到此文件
      if [ "$?" == "2" ]; then return 2; fi
    fi
    # 如果是目录就生成
    if [ -d "$1" ]; then
      # 计算被备份文件的hsa1信息
      mkdir -p "${3:-./}"
      find $1/* -name "*" -type f -exec ${HashType}sum {} \; | sed 's/  /,/' > ${3:+$3/}${HashType}.csv
    fi
    return 0;
  else
    # 指定的文件或目录不存在
    return 1;
  fi
}

function InitServerInfo() {
  # 备份目录
  BackupDir="Backup"
  # 配置文件备份目录
  BackupConfigDir="$BackupDir/Config"
  BackupHashDir="$BackupDir/Hash"
  if [[ -z "$BACKUPNAME" || "$BACKUPNAME" == "(def)" ]]; then
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
  local Info_AboutStartBacking=`GetI18nText Info_AboutStartBacking "About to start backing up the server"`
  echo "${Info_AboutStartBacking}"
  # 这里自动创建目录替代运维人员手动了
  mkdir -p ${BackupDir}/{Config,Hash}
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
    ArchiveBackup "${BackupDir}" "${BackupFileName}"
  else
    GetI18nText Info_NotFoundBackupDir "Backup folder not found, if you want to backup, you need to create this folder, if you want to backup configuration files, you need to create Backup/Config folder."; > /dev/stderr
  fi

  date
  GetI18nText Info_CompleteOperation "Complete the operation."
  return 0
}

# 还原服务器存档
function Recover() {
  # 记录记录是否需要重新拉起服务
  local RestartServer=false

  # 检查备份目录与备份的存档文件是否存在
  if [[ -d "${BackupDir}" && -e "${BackupFileName}" ]]; then
    local Info_AboutStartRecover=`GetI18nText Info_AboutStartRecover "The backup is about to be restored"`
    echo "${Info_AboutStartRecover}"
    ExistServerExample
    if [ $? -eq 0 ]; then
      RestartServer=true
      cmd2server 'save-all flush'
      minecraftctl stop "${Info_AboutStartRecover}"
    fi
    # 在这里检测目标存档是否存在hash(sha1)表, 存在就使用更加轻量的算法进行回档
    GetI18nText Info_CheckArchiveFile "Check archive file..."
    GetHashList "${BackupFileName}" 'sha1'
    if [ "$?" == "0" ]; then
      # 存在sha1文件, 才为服务器现有存档生成sha1表
      GetHashList "${LevelName}" 'sha1' "./"
      mv -f "./sha1.csv" "${BackupHashDir}/sha1_.csv";
      sed -i 's/,Backup\//,/' "${BackupHashDir}/sha1.csv"
      # 这里使用diff命令进行比较, 并且使用awk进行处理
      local flag=false
      local RecoverList=''
      # 开始比较存档差异
      GetI18nText Info_StartComparingArchiveDifferences "Start comparing archive differences"
      while read line
      do
        flag=true
        local Option="${line%\|*}"
        local TargetFile="${line#*\|}"
        # 检查文件是针对于谁加的
        if [ "${Option}" == "-" ];then
          mkdir -p `dirname "${BackupDir}/${TargetFile}"`
          mv -f "${TargetFile}" "${BackupDir}/${TargetFile}"
        fi
        if [ "${Option}" == "+" ];then
          RecoverList="${RecoverList} ${BackupDir}/${TargetFile}"
        fi
      done < <(diff -u ""${BackupHashDir}/sha1_.csv"" "${BackupHashDir}/sha1.csv" | awk -F, 'NR>3{sub(/[0-9a-f]*$/, "", $1);if($1 != " ") print $1"|"$2}')
      # 提前删除哈希表缓存避免干扰差异包打包(这里的顺序就是"来源=>目的地"")
      rm -f "${BackupHashDir}/sha1.csv" "${BackupHashDir}/sha1_.csv"
      # 这里是检测diff状态, 如果未进入while, 就说明文件相同, 直接弹出即可
      if [ "${flag}" == "false" ]; then 
        GetI18nText Info_NoNeedRecover "No need to recover, the backup is the same as the current server."
        return 0;
      fi
      # 生成回滚补丁文件
      GetI18nText Info_GenerateRevertPatch "Generate revert patch(revert)..."
      ArchiveBackup "${BackupDir}" "${BackupDir}/Backup-revert.tar.xz"
      # 从配置中解压指定的文件
      tar -C . -xf "${BackupFileName}" ${RecoverList}
      rm -f "${BackupHashDir}/*"
    else
      # 删除当前服务器的存档(这里提前删除是避免空间不足)
      if [ -d "${LevelName}" ]; then rm -rf "${LevelName}"; fi
      if [ -d "${LevelNether}" ]; then rm -rf "${LevelNether}"; fi
      if [ -d "${LevelEnd}" ]; then rm -rf "${LevelEnd}"; fi
      GetI18nText Info_unArchiveing "Decompressing the archive..."
      # 解压对应的文件
      tar -C . -xf "${BackupFileName}" "${BackupDir}/${BackupLevelName}"
    fi
    date
    # 恢复数据
    GetI18nText Info_RecoverDataing "Recovering data..."
    if [ ! -d "${BackupDir}/${BackupLevelName}" ]; then mv "${BackupDir}/${BackupLevelName}" "${LevelName}"; fi
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
    if [ -d "${BackupDir}" ]; then echo "${BackupDir}: YES"; else echo "${BackupDir}: NO"; fi
    if [ -f "${BackupFileName}" ]; then echo "${BackupFileName}: YES"; else echo "${BackupFileName}: NO"; fi
    GetI18nText Info_NotFoundBackupFileORDir "The Backup folder is not found or the corresponding backup is not found. Please enter the correct name. If there is a space in the name, please wrap it in double quotation marks."; > /dev/stderr
    return 1
  fi
  GetI18nText Info_CompleteOperation "Complete the operation."
  if [ "$RestartServer" == "true" ]; then minecraftctl start; fi
  return 0
}

# 列出可还原的备份列表(按最近修改时间排序)
function BackupList() {
  local Info_BackupListTitle=`GetI18nText Info_BackupListTitle "name\tcreate/change time\tfile size"`
  ls -lqth Backup/Backup*.tar.xz 2>/dev/null | awk -F ' '\
  "BEGIN{print \"$Info_BackupListTitle\"}\
  {\
    gsub(/^Backup\/Backup-?|\.tar\.xz$/, \"\", \$8)\
    gsub(/_/, \" \", \$8);\
    if(\$8 == \"\") \$8=\"(def)\"\
  }\
  {print \$8\"\t\"\$6\" \"\$7\"\t\"\$5};"
  return 0;
}

# 删除选中的服务器备份
function Remove() {
  if [ -e "${BackupFileName}" ]; then
    rm -f "${BackupFileName}"
    BackupList
    return 0;
  else
    return 1;
  fi
}

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "Back up or restore server archives"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl backup [-n BackupName] [-h[mini]|r|l] [--rm]\n"
  GetI18nText Help_module_content "  -n,\t--backupname\tthe name of the backup\n  -r,\t--recover\tChange mode to restore archive mode (service process will be restarted)\n  -l,\t--list\t\tList the backups that can be restored\n  \t--rm\t\tDeletes the specified server backup\n  -h,\t--help\t\tGet this help menu"
  return 0;
}

ARGS=`getopt -o n:lrh:: -l name:,rm,list,recover,help:: -- "$@"`
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
    --rm)
      MODE="Remove"
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
#!/bin/bash
###
 # @Date: 2022-07-24 14:01:03
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-25 11:31:07
 # @Description: 备份服务器
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

# TODO 实现BackupName功能

source $InstallPath/tools/Base.sh

# 在官方核心的状态下备份服务器
function BackupInofficial() {
  date
  echo "官方核心模式备份数据中..."
  if [ -d "Backup" ]; then
    if [ -d "Backup/world" ]; then
      # 如果备份数据存在,就将其删除
      rm -rf "Backup/world"
    fi
    cp -r "world" "Backup/world"
    if [ -d "Backup/world_nether" ]; then
      rm -rf "Backup/world_nether"
    fi
    cp -r "world/DIM-1" "Backup/world_nether"
    if [ -d "Backup/world_the_end" ]; then
      rm -rf "Backup/world_the_end"
    fi
    cp -r "world/DIM1" "Backup/world_the_end"
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
    fi
    # 迁移跑图区块
    #if [ -d "Backup/mcaFile" ]; then
    # 如果文件夹存在，就开始迁移
    # 迁移主世界区块文件
    #if [ ! -d "Backup/mcaFile/master" ]; then mkdir ./Backup/mcaFile/master/ fi;
    #find ./world/region/ -size 12288c -exec mv -f {} ./Backup/mcaFile/master/ \;
    #fi
  fi
}

# 在非官方核心的状态下备份服务器
function BackupInUnofficial() {
  date
  echo "非官方核心模式备份数据中..."
  if [ -d "Backup" ]; then
    if [ -d "Backup/world" ]; then
      # 如果备份数据存在,就将其删除
      rm -rf "Backup/world"
    fi
    cp -r "world" "Backup/world"
    if [ -d "Backup/world_nether" ]; then
      rm -rf "Backup/world_nether"
    fi
    cp -r "world_nether" "Backup/world_nether"
    if [ -d "Backup/world_the_end" ]; then
      rm -rf "Backup/world_the_end"
    fi
    cp -r "world_the_end" "Backup/world_the_end"
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
    fi
    # 迁移跑图区块
    #if [ -d "Backup/mcaFile" ]; then
    # 如果文件夹存在，就开始迁移
    # 迁移主世界区块文件
    #if [ ! -d "Backup/mcaFile/master" ]; then mkdir ./Backup/mcaFile/master/ fi;
    #find ./world/region/ -size 12288c -exec mv -f {} ./Backup/mcaFile/master/ \;
    #fi
  fi
}

# 备份服务器存档
function Backup() {
  GetServerCoreVersion
  case $? in
  1)
    BackupInofficial
    ;;

  2)
    BackupInUnofficial
    ;;
  *)
    echo 配置存在问题,服务器核心未知,无法进行备份.;date;exit 1;
    ;;
  esac
  date
  echo "备份完成，正在归档(归档期间可以放后台自己跑)..."
  # 移出备份存档
  if [ -e "Backup/Backup.tar.xz" ]; then
    mv "Backup/Backup.tar.xz" ./
  fi
  mv Backup/Backup*.tar.xz ./ 2>/dev/null
  # 将备份好的文件进行压缩(默认使用稳妥的1线程和6的压缩比率)
  if [[ ${BackupThread} == 1 ]] && [[ ${BackupCompressLevel} == 6 ]]; then 
    tar -Jcf Backup.tar.xz Backup/*
  else
    XZ_OPT="-${BackupCompressLevel}T ${BackupThread}" tar -cJf "Backup.tar.xz" Backup/* 
  fi
  # 删除多余的备份文件
  rm -rf Backup/world* Backup/Config/*
  # 移回备份存档
  mv Backup*.tar.xz Backup/ 2>/dev/null
  date
  echo 完成操作.
}

#* show this help menu
function helpMenu() {
  echo -e "Backup the server archive (if the server is running, an emergency backup is made)"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  # echo -e "Usage: minecraftctl backup [-n BackupName] [-h[mini]]\n"
  echo -e "Usage: minecraftctl backup [-h[mini]]\n"
  # echo -e "  -n,\t--backupname\t\tthe name of the backup file"
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

date
echo 即将开始备份服务器
minecraftctl say '即将开始备份服务器'
cmd2server 'save-all flush'
Backup
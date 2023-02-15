#!/bin/bash
###
 # @Date: 2022-07-24 14:01:03
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-02-15 23:39:47
 # @Description: 备份服务器
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

BACKUPNAME=''
MODE='Backup'

# 将提交的文件路径进行翻译, 将备份路径与实际服务器存档路径相互转换(注意, 这不适用于目录本身)
#?$1|必须: 指定需要翻译的文件路径, 如果它是以${BackupDir}开头的, 会被认为是要从备份目录恢复到服务器目录
# return:
#   0: 完成任务
#   1: 需要指定$1
function TranslatePath() {
  # 首先检查$1是否存在或者是否为空
  if [[ -z "$1" ]]; then return 1; fi
  # 处理两种方向的翻译
  if [[ "$1" =~ ^${BackupDir} ]]; then
    #*将备份文件路径转换为服务器文件路径
    # 进行替换操作
    local TargetFile=`sed "s/^${BackupDir}\///" <<< "${1}"`
    # 预处理LevelEnd, 将/替换为\/, 这样才能在sed中使用
    local Temp=${LevelEnd//\//\\/}
    # 替换前缀路径
    TargetFile=`sed "s/^${BackupLevelName}\/DIM1/${Temp}/" <<< "${TargetFile}"`
    Temp=${LevelNether//\//\\/}
    TargetFile=`sed "s/^${BackupLevelName}\/DIM-1/${Temp}/" <<< "${TargetFile}"`
    # 将UnOfficial路径信息删除, 因为这个目录是备份文件独有的, 其目录结构与服务器目录结构相同
    TargetFile=`sed "s/^UnOfficial\/\|Config\///" <<< "${TargetFile}"`
    # 对全局配置特殊处理
    TargetFile=`sed "s/^config$/\/etc\/minecraftctl\/config/" <<< "${TargetFile}"`
  else
    #*将服务器文件路径转换为备份文件路径
    # 初始化目标路径
    local TargetFile=${1}
    # 预处理LevelEnd, 将/替换为\/, 这样才能在sed中使用
    local Temp=${LevelEnd//\//\\/}
    # 替换前缀路径
    TargetFile=`sed "s/^${Temp}/${BackupLevelName}\/DIM1/" <<< "${TargetFile}"`
    Temp=${LevelNether//\//\\/}
    TargetFile=`sed "s/^${Temp}/${BackupLevelName}\/DIM-1/" <<< "${TargetFile}"`
    # 增加UnOfficial路径信息, 这个时候还没被替换的只有额外的元数据了
    TargetFile=`sed "s/^world_nether\|world_the_end/UnOfficial\/${TargetFile%%\/*}/" <<< "${TargetFile}"`
    # 特殊的全局配置加入到Config目录下
    TargetFile=`sed "s/^\/etc\/minecraftctl\///" <<< "${TargetFile}"`

    # 到这里所有路径都被删除的数据肯定就是服务器配置数据了
    if [ `dirname ${TargetFile}` == '.' ]; then 
      TargetFile="Config/${TargetFile}"
    fi
    # 进行统一替换操作
    TargetFile="${BackupDir}/${TargetFile}"
  fi
  unset Temp
  echo "${TargetFile}"
  return 0;
}

# 打印指定文件或文件夹的指定Hash列表
#?$1|必须: 指定的目标, 可以为目录或者压缩文件, 当为文件夹时会生成此文件夹的hash列表, 当为压缩文件时会提取Hash目录下的内容
#?$2|必须: 指定的hash类型, 允许的值为: sha1, sha224, sha256, sha384, sha512, md5
#?$3|可选: $1为目录时生效, 指定一个的目录列表以限制生成的范围, 以逗号分隔, 例如: world,UnOfficial
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
  grep -qw "$2" <<< "${AllowHashTypes[@]}"
  if [ "$?" == "0" ]; then HashType="$2"; fi

  # 确认目标文件是存在的
  if [ -e "$1" ]; then
    # 如果是文件就提取这个文件
    if [ -f "$1" ]; then
      mkdir -p /tmp/minecraftctl/backup
      tar -C /tmp/minecraftctl/backup -xf "$1" "${BackupDir}/Hash/${HashType}.csv" 2>/dev/null
      # 压缩包中找不到此文件
      if [ "$?" == "2" ]; then return 2; fi
      cat "/tmp/minecraftctl/backup/${BackupDir}/Hash/${HashType}.csv"
      rm -rf /tmp/minecraftctl/backup
    fi
    # 如果是目录就生成
    if [ -d "$1" ]; then
      # 计算被备份文件的hash信息
      # find Backup -iregex "^Backup\/\(world\|UnOfficial\).*" -type f
      find ${1} -iregex "^${1}\/${3:+\(${3//,/\\|}\)}.*" -type f -exec ${HashType}sum {} \; | sed 's/  /,/'
    fi
    return 0;
  else
    # 指定的文件或目录不存在
    return 1;
  fi
}

# 清理NewDirStruct产生的文件与目录
function CleanDirStruct() {
  # 删除临时的备份文件
  rm -rf "${BackupDir}/world" ${BackupDir}/Config/* ${BackupDir}/Hash/* "${BackupDir}/UnOfficial"
}

# 按照InitServerInfo计算后的配置, 将存档以新的格式组织起来, 以便后续的操作
function NewDirStruct() {
  # 这里自动创建目录替代运维人员手动了
  mkdir -p ${BackupDir}/{Config,Hash}
  # 清理备份缓存
  CleanDirStruct
  # 解释: 这里使用cp而不是ln是因为有可能备份时文件正在被修改, 导致Hash不一致.
  #      至于cp带来的额外IO, 其实在Linux中并不存在, 这里利用了Linux下的一个小技巧:
  #      在Linux中, cp并不会真正的复制文件, 而是创建一个文件链接指向此时的文件i节点, 直到被拷贝到 文件被修改, 才会分配空间
  #      所以这里其实也是ln, 只是ln的是文件的i节点, 不会再随着文件的变化而变化, 由于Linux下缓存机制的存在, 文件甚至大概率不会落地就被删除了
  if [ "${OfficialCore}" == "false" ]; then
    mkdir -p "${BackupDir}/UnOfficial"
    # 当第三方核心下界存档存在时
    if [ -d "${LevelNether/\/DIM-1/}" ]; then
      # 创建第三方核心目录
      mkdir -p `TranslatePath "${LevelNether/\/DIM-1/}"`
      find ${LevelNether/\/DIM-1/} -maxdepth 1 -type f -exec cp {} `TranslatePath "${LevelNether/\/DIM-1/}"` \;
    fi
    if [ -d "${LevelEnd/\/DIM1/}" ]; then
      mkdir -p `TranslatePath "${LevelEnd/\/DIM1/}"`
      find ${LevelEnd/\/DIM1/} -maxdepth 1 -type f -exec cp {} `TranslatePath "${LevelEnd/\/DIM1/}"` \;
    fi
  fi
  cp -r "${LevelName}" "$BackupDir/${BackupLevelName}"
  # 备份各个维度的内容
  if [ ! -d "${BackupLevelNether}" ]; then
    cp -r "${LevelNether}" "${BackupLevelNether}";
  fi
  if [ ! -d "${BackupLevelEnd}" ]; then
    cp -r "${LevelEnd}" "${BackupLevelEnd}";
  fi

  # 备份配置文件
  if [ -d "${BackupConfigDir}" ]; then
    for item in 'server.properties' 'ops.json' '/etc/minecraftctl/config' 'minecraftctl.conf'; do
      cp -lf "${item}" `TranslatePath "${item}"`
    done
  fi
  # 迁移跑图区块
  #if [ -d "Backup/mcaFile" ]; then
  # 如果文件夹存在，就开始迁移
  # 迁移主世界区块文件
  #if [ ! -d "Backup/mcaFile/master" ]; then mkdir ./Backup/mcaFile/master/ fi;
  #find ./world/region/ -size 12288c -exec mv -f {} ./Backup/mcaFile/master/ \;
  #fi
  return 0;
}

# 为备份目录生成归档文件
#?$1|必须: 指定需要归档的目录
#?$2|必须: 指定输出文件的文件名
function ArchiveBackup() {
    # 如果存在同名归档文件就删除
    if [ -e "${2}" ]; then
      rm -rf "${2}";
    fi
    # 移出备份存档
    mv Backup/Backup*.tar.xz ./ 2>/dev/null
    GetHashList "${1}" 'sha1' "${BackupLevelName},UnOfficial" > "${1}/Hash/sha1.csv"
    GetHashList "${1}" 'md5' "${BackupLevelName},UnOfficial" > "${1}/Hash/md5.csv"
    # 将备份好的文件进行压缩(默认使用稳妥的1线程和6的压缩比率)
    if [[ ${BackupThread} == 1 ]] && [[ ${BackupCompressLevel} == 6 ]]; then 
      tar -Jcf "${2}" ${1}/*
    else
      XZ_OPT="-${BackupCompressLevel}T ${BackupThread}" tar -cJf "${2}" ${1}/* 
    fi
    # 移回备份存档
    mv Backup*.tar.xz "${1}/" 2>/dev/null
    CleanDirStruct
    return 0;
}

# 初始化本次实例的配置
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
    OfficialCore=false
    LevelNether="${LevelName}_nether/DIM-1"
    LevelEnd="${LevelName}_the_end/DIM1"
  elif [ "$?" == "1" ]; then
    # 是否为官方模式
    OfficialCore=true
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
  # 检查服务器是否正在运行, 如果正在运行就向服务器内发送提示并写入脏页
  ExistServerExample
  if [ $? -eq 0 ]; then
    minecraftctl say -m "${Info_AboutStartBacking}"
    cmd2server 'save-all flush'
  fi

  # 首先检查备份目录是否存在
  if [ -d "$BackupDir" ]; then
    # 将服务器存档以新的目录结构放置在待备份目录中
    NewDirStruct
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
    # 在这里检测原始路径是否存在${LevelName}文件夹且目标存档是否存在hash(sha1)表, 存在${LevelName}文件夹并且存在hash表就使用更加轻量的算法进行回档[0]
    local RecoverMode="0"
    GetI18nText Info_CheckRecEnving "Checking the recovery environment..."
    if [ ! -d ${LevelName} ]; then RecoverMode="1"; fi;
    if [ "${RecoverMode}" != "1" ]; then
      GetHashList "${BackupFileName}" 'sha1' >  "sha1_.csv"
      RecoverMode="$?"
    fi
    if [ "${RecoverMode}" == "0" ]; then
      # 存在sha1文件, 才为服务器现有存档生成sha1表
      # 生成现有存档的sha1表
      NewDirStruct
      # 生成Hash
      GetHashList "${BackupDir}" 'sha1' "${BackupLevelName},UnOfficial" > "sha1.csv"
      CleanDirStruct
      # 把hash表移动到备份目录进行计算
      mv -f sha1*.csv "${BackupHashDir}/";
      # 这里使用diff命令进行比较, 并且使用awk进行处理
      local flag=false
      local RecoverList=''
      # 开始比较存档差异(为生成补丁包做好准备)
      GetI18nText Info_StartComparingArchiveDifferences "Start comparing archive differences"
      while read line; do
        # 操作标签
        local Option="${line%\|*}"
        # 备份目的地(这个路径从hash表中拿到)
        local BackupTargetFile="${line#*\|}"
        # 官方模式下跳过UnOfficial文件夹
        if [[ "${OfficialCore}" == "true"  && "${BackupTargetFile}" =~ ^${BackupDir}"/UnOfficial"* ]]; then
          continue
        fi
        flag=true
        # 等待备份的文件(这里将hash表翻译为服务器中的路径)
        local TargetFile=`TranslatePath "${BackupTargetFile}"`
        # 在这里对文件操作进行区分
        if [ "${Option}" == "-" ];then
          #*当为删除操作时, 将文件移动到备份目录准备生成补丁包
          # 提前在备份路径创建好文件夹
          mkdir -p `dirname "${BackupTargetFile}"`
          # 从服务器存档提取文件到备份目录
          mv -f "${TargetFile}" "${BackupTargetFile}"
        fi
        if [ "${Option}" == "+" ];then
          #*当为添加操作时, 将文件路径写入数组, 准备后续从备份包中提取文件
          RecoverList="${RecoverList} ${BackupTargetFile}"
        fi
      done < <(diff -u "${BackupHashDir}/sha1.csv" "${BackupHashDir}/sha1_.csv" | awk -F, 'NR>2{sub(/[0-9a-f]*$/, "", $1);if($1 == "+" || $1 == "-") print $1"|"$2}')
      # 提前删除哈希表缓存避免干扰差异包打包(这里的顺序就是"来源=>目的地"")
      rm -f "${BackupHashDir}/sha1_.csv" "${BackupHashDir}/sha1.csv"
      # 这里检测diff状态, 如果从未进入过while, 就说明文件相同, 直接弹出即可
      if [ "${flag}" == "false" ]; then 
        GetI18nText Info_NoNeedRecover "No need to recover, the backup is the same as the current server."
        return 0;
      fi
      # 生成回滚补丁文件
      GetI18nText Info_GenerateRevertPatch "Generate revert patch(revert)..."
      ArchiveBackup "${BackupDir}" "${BackupDir}/Backup-revert.tar.xz"
      # 从配置中解压指定的文件
      tar -C . -xf "${BackupFileName}" ${RecoverList}
      # hash此时已经用不上了, 可以删掉了
      rm -f "${BackupHashDir}/*"
    else
      # (完整模式)删除当前服务器的存档(这里提前删除是避免空间不足)
      if [ -d "${LevelName}" ]; then rm -rf "${LevelName}"; fi
      if [ -d "${BackupLevelName}_nether" ]; then rm -rf "${BackupLevelName}_nether"; fi
      if [ -d "${BackupLevelName}_the_end" ]; then rm -rf "${BackupLevelName}_the_end"; fi
      GetI18nText Info_unArchiveing "Decompressing the archive..."
      # 解压对应的文件
      tar -C . -xf "${BackupFileName}"
      # 如果有地狱和末地, 将他们移动到UnOfficial目录下, 以兼容旧版本备份程序
      if [ -d "${BackupDir}/${BackupLevelName}_nether" ]; then
        mkdir -p "${BackupDir}/UnOfficial"
        mv -f "${BackupDir}/${BackupLevelName}_nether" "${BackupDir}/UnOfficial/"
        # 将游戏数据移动到官方目录以支持相互转换
        if [ -d "${BackupDir}/${BackupLevelName}_nether/DIM-1" ]; then
          mv -f "${BackupDir}/${BackupLevelName}_nether/DIM-1" "${BackupDir}/${BackupLevelName}/"
        fi
      fi
      if [ -d "${BackupDir}/${BackupLevelName}_the_end" ]; then
        mkdir -p "${BackupDir}/UnOfficial"
        mv -f "${BackupDir}/${BackupLevelName}_the_end" "${BackupDir}/UnOfficial/"
        # 将游戏数据移动到官方目录以支持相互转换
        if [ -d "${BackupDir}/${BackupLevelName}_the_end/DIM1" ]; then
          mv -f "${BackupDir}/${BackupLevelName}_the_end/DIM1" "${BackupDir}/${BackupLevelName}/"
        fi
      fi
    fi
    date
    # 恢复数据
    GetI18nText Info_RecoverDataing "Recovering data..."
    # 到这里的时候, Backup中已经存放了所有需要恢复的文件, 现在只要把文件复制回去就好了
    while read Target
    do
      DirTarget=`TranslatePath "${Target}"`
      mkdir -p `dirname "${DirTarget}"`
      mv -f "${Target}" "${DirTarget}"
    done < <(GetHashList "${BackupDir}" 'sha1' "${BackupLevelName},UnOfficial" | awk -F, '{print $2}')
    CleanDirStruct
    return 0
    # 迁移跑图区块
    #if [ -d "Backup/mcaFile" ]; then
    # 如果文件夹存在，就开始迁移
    # 迁移主世界区块文件
    #if [ ! -d "Backup/mcaFile/master" ]; then mkdir ./Backup/mcaFile/master/ fi;
    #find ./world/region/ -size 12288c -exec mv -f {} ./Backup/mcaFile/master/ \;
    #fi
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
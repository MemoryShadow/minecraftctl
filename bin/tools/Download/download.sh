#!/bin/bash
###
 # @Date: 2022-06-25 23:51:25
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-04 21:09:05
 # @Description: 对传入URL进行分析并尝试找到最合适的下载方式
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

function helpMenu() {
  echo -e "${0} -u <URL> [-o [OutputFile] [--md5|sha1]=[Hash]]"
  echo -e "  -u,\t--url\t\tThe URL of the file waiting to be downloaded"
  echo -e "  -o,\t--output\tThe name of the output file"
  echo -e "  -h,\t--help\t\tGet this help menu"
  echo -e "  \t--md5|sha1\tSpecifies how the hash value is verified after the file download is complete.\n\t\t\tIf there are multiple flags, only the one closest to the left of this list will take effect"
}

# 将镜像列表合并为多来源下载的参数
function ImageList2DLpara() {
  local DownloadDomain=$1
  local DownloadURL=""
  for Domain in ${DownloadDomain[@]};
  do
    DownloadURL="${DownloadURL} ${Domain}/$2"
  done
  echo ${DownloadURL}
}

ARGS=`getopt -o u:o:h -l url:,output:,md5:,sha1:,help -- "$@"`
if [ $? != 0 ]; then
    echo "Terminating..."
    exit 1
fi

#将规范化后的命令行参数分配至位置参数（$1,$2,...)
eval set -- "${ARGS}"

URL=''
OUTPUT=''
MD5=''
SHA1=''

while true
do
  case "$1" in
    -u|--url)
      URL="$2";
      shift 2
      ;;
    -o|--output)
      OUTPUT="$2";
      shift 2
      ;;
    --md5)
      MD5="$2";
      shift 2
      ;;
    --sha1)
      SHA1="$2";
      shift 2
      ;;
    -h|--help)
      helpMenu
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Internal error!"
      exit 1
      ;;
  esac
done

if [ -z "$URL" ]; then echo -e "The parameter does not exist, please pass in the version number to be queried\n"; helpMenu; exit 1; fi;

# 拥有镜像源的域名列表
declare -A AllowDownloadMirror=(
  ['https://launcher.mojang.com']="BMCLAPI_def"
  ['http://launchermeta.mojang.com']="BMCLAPI_def"
  ["https://files.minecraftforge.net"]="BMCLAPI_def"
  ["https://authlib-injector.yushi.moe"]="BMCLAPI_AI"
)

# 支持下载的项目列表
AllowDownloadItems=(
  "vanilla"
  "forge"
  "authlib-injector"
  "mohist"
  "paper"
  "purpur"
)

# BMCLAPI镜像列表
BMCLAPI_def=(
  "https://bmclapi2.bangbang93.com"
  "https://download.mcbbs.net"
)

BMCLAPI_AI=(
  "https://bmclapi2.bangbang93.com/mirrors/authlib-injector"
  "https://download.mcbbs.net/mirrors/authlib-injector"
)

# 获取域名并检测是否存在镜像源
TargetHost=`echo ${URL} | grep -oP '^[a-z]*?://.*?/'`
if [ -z ${AllowDownloadMirror[${TargetHost%/*}]} ]; then
  DownloadURL=${URL}
else
  echo "==============================================================================="
  echo "This high-speed download is partially accelerated by the BMCL project to provide some accelerated support"
  # 如果存在镜像源，就识别变量准备合成下载参数
  eval "DownloadDomain=(\"\${${AllowDownloadMirror[${TargetHost%/*}]}[@]}\")"
  # 将源站写入下载源中
  DownloadDomain[${#DownloadDomain[@]}]=${TargetHost%/*}
  DownloadURL=`ImageList2DLpara "${DownloadDomain[*]}" "${URL#*${TargetHost}}"`
  echo "==============================================================================="
fi
if [ -z "$OUTPUT" ]; then
  OUTPUT=${URL##*/}
  aria2c -c -s 9 --min-split-size 3M ${DownloadURL}
else
  aria2c -c -s 9 --min-split-size 3M -o $OUTPUT ${DownloadURL}
fi

if [ ! -z ${MD5}${SHA1} ] ; then
  if [ ! -z ${MD5} ] ; then
    md5sum ${OUTPUT} | grep ${MD1} > /dev/null
  elif [ ! -z ${SHA1} ] ; then
    sha1sum ${OUTPUT} | grep ${SHA1} > /dev/null
  fi
fi

if [ $? -ne 0 ]; then
  echo "Hash check failed, script has exited";exit 3;
else
  if [ ! -z ${AllowDownloadMirror[${TargetHost%/*}]} ]; then
    echo "==============================================================================="
    echo "This high-speed download is partially accelerated by the BMCL project to provide some accelerated support"
    echo "==============================================================================="
  fi
  echo "File download and hash check succeeded";exit 0;
fi

#!/bin/bash
###
 # @Date: 2022-06-25 23:51:25
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-06 13:11:18
 # @Description: Analyze incoming URLs and try to find the most suitable download method
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

#* show this help menu
function helpMenu() {
  echo -e "${0} -u <URL> [-o <OutputFile>] [--md5|sha1=<Hash>] [-h]"
  echo -e "  -u,\t--url\t\tThe URL of the file waiting to be downloaded"
  echo -e "  -o,\t--output\tThe name of the output file"
  echo -e "  -h,\t--help\t\tGet this help menu"
  echo -e "  \t--md5|sha1\tSpecifies how the hash value is verified after the file download is complete.\n\t\t\tIf there are multiple flags, only the one closest to the left of this list will take effect"
}

#* Merge mirrorlists into parameters for multi-source downloads
#? @param $1|must: mirror list prefix
#? @param $2|must: URL suffix to download
#? @return: Multi-source download parameters recognized by aria2
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
    helpMenu > /dev/stderr;exit 1;
fi

# Assign normalized command line arguments to positional arguments（$1,$2,...)
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
      echo "Internal error!" > /dev/stderr;
      exit 1
      ;;
  esac
done

if [ -z "${URL}" ]; then echo -e "The parameter does not exist, please pass in the version number to be queried\n" > /dev/stderr; helpMenu > /dev/stderr; exit 1; fi;

# List of domain names with mirror sources
declare -A AllowDownloadMirror=(
  ['http://launcher.mojang.com']="BMCLAPI_def"
  ['https://launcher.mojang.com']="BMCLAPI_def"
  ['http://launchermeta.mojang.com']="BMCLAPI_def"
  ["https://files.minecraftforge.net"]="BMCLAPI_def"
  ["https://authlib-injector.yushi.moe"]="BMCLAPI_AI"
)

# BMCLAPI mirror list
BMCLAPI_def=(
  "https://bmclapi2.bangbang93.com"
  "https://download.mcbbs.net"
)

BMCLAPI_AI=(
  "https://bmclapi2.bangbang93.com/mirrors/authlib-injector"
  "https://download.mcbbs.net/mirrors/authlib-injector"
)

# Get the domain name and detect whether there is a mirror source
TargetHost=`echo ${URL} | grep -oP '^[a-z]*?://.*?/'`
if [ -z ${AllowDownloadMirror[${TargetHost%/*}]} ]; then
  DownloadURL=${URL}
else
  echo "==============================================================================="
  echo "This high-speed download is partially accelerated by the BMCL project to provide some accelerated support"
  # If there is a mirror source, identify the variables and prepare to synthesize download parameters
  eval "DownloadDomain=(\"\${${AllowDownloadMirror[${TargetHost%/*}]}[@]}\")"
  # Write the source site to the download source list
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
  if [ $? -ne 0 ]; then
    echo "Hash check failed, script has exited";exit 3;
  else
    # Re-credit the BMCL project after verifying the hash successfully, to avoid negative reputation after download failure
    if [ ! -z ${AllowDownloadMirror[${TargetHost%/*}]} ]; then
      echo "==============================================================================="
      echo "This high-speed download is partially accelerated by the BMCL project to provide some accelerated support"
      echo "==============================================================================="
    fi
    echo "File download and hash check succeeded";exit 0;
  fi
else
  echo "file download complete";exit 0;
fi

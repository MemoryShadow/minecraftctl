#!/bin/bash
###
 # @Date: 2022-06-25 23:51:25
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-09-09 15:06:04
 # @Description: Analyze the incoming URL and try to use the most appropriate download method found
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 

source $InstallPath/tools/Base.sh

cd $WorkDir

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "Analyze the incoming URL and try to use the most appropriate download method found"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl download -u <URL> [-o <OutputFile>] [--md5|sha1=<Hash>] [-h[mini]]\n"
  GetI18nText Help_module_content "  -u,\t--url\t\tThe URL of the file waiting to be downloaded\
  \n  -o,\t--output\tThe name of the output file\n  -h,\t--help\t\tGet this help menu\
  \n  \t--md5|sha1|sha256\n\t\tSpecifies how the hash value is verified after the file download is complete.\
  \n\t\t\tIf there are multiple flags, only the one closest to the left of this list will take effect"
  return 0;
}

#*Merge mirrorlists into parameters for multi-source downloads
#?@param $1|must: mirror list prefix
#?@param $2|must: URL suffix to download
#?@return(echo): Multi-source download parameters recognized by aria2
function ImageList2DLpara() {
  local DownloadDomain=$1
  local DownloadURL=""
  for Domain in ${DownloadDomain[@]}; do
    DownloadURL="${DownloadURL} ${Domain}/$2"
  done
  echo ${DownloadURL}
}

#*Merge mirrorlists into parameters for multi-source downloads
#?@param $1|optional: mirror list prefix
#?@return: Multi-source download parameters recognized by aria2
function Thanks() {
  if [ -z $1 ]; then return 1;fi
  echo "==============================================================================="
  case "${1}" in
    BMCLAPI)
      GetI18nText Thanks_module_BMCLAPI "This high-speed download is partially accelerated by the BMCL project to provide some accelerated support"
    ;;
    GITHUB)
      GetI18nText Thanks_module_GITHUB "This high-speed download is partially accelerated by ghproxy.com, Cloudflare Workers, fastgit.org to provide partial acceleration support"
    ;;
  esac
  echo "==============================================================================="
  return 0
}

ARGS=`getopt -o u:o:h:: -l url:,output:,md5:,sha1:,sha256:,help:: -- "$@"`
if [ $? != 0 ]; then
    helpMenu > /dev/stderr;exit 1;
fi

# Assign normalized command line arguments to positional arguments（$1,$2,...)
eval set -- "${ARGS}"

URL=''
OUTPUT=''
MD5=''
SHA1=''
SHA256=''

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
    --sha256)
      SHA256="$2";
      shift 2
      ;;
    -h|--help)
      helpMenu "$2"
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

if [ -z "${URL}" ]; then GetI18nText Error_Missing_parameters_version "The parameter does not exist, please pass in the version number to be queried\n" > /dev/stderr; helpMenu > /dev/stderr; exit 1; fi;
if [ -z "${OUTPUT}" ]; then OUTPUT=${URL##*/}; fi

if [ -e "${OUTPUT}" ] && [[ ! -z "${MD5}" || ! -z "${SHA1}" ]]; then
  if [ ! -z ${MD5} ] ; then
    grep -q ${MD1} < <(md5sum ${OUTPUT})
  elif [ ! -z ${SHA1} ] ; then
    grep -q ${SHA1} < <(sha1sum ${OUTPUT}) 
  fi
  if [ $? == 0 ]; then GetI18nText Info_NoNeedDownloadFiles "The file ${OUTPUT} already exists and the hash value is correct, no need to download\n" ${OUTPUT}; exit 0; fi
fi

# List of domain names with mirror sources
# TODO: Ignore the difference between https and http
declare -A AllowDownloadMirror=(
  ['https://github.com']="GITHUB_def"
  ['https://raw.githubusercontent.com']="GITHUB_raw"
  ['http://launcher.mojang.com']="BMCLAPI_def"
  ['https://launcher.mojang.com']="BMCLAPI_def"
  ['http://launchermeta.mojang.com']="BMCLAPI_def"
  ['https://launchermeta.mojang.com']="BMCLAPI_def"
  ['https://files.minecraftforge.net']="BMCLAPI_def"
  ['http://resources.download.minecraft.net']="BMCLAPI_Assets"
  ['https://libraries.minecraft.net']="BMCLAPI_Maven"
  ['https://maven.minecraftforge.net']="BMCLAPI_Maven"
  ['https://files.minecraftforge.net/maven']="BMCLAPI_Maven"
  ['https://maven.fabricmc.net']="BMCLAPI_Maven"
  ['https://authlib-injector.yushi.moe']="BMCLAPI_AI"
)

# Github mirror list
GITHUB_def=(
  "https://ghproxy.com/https://github.com"
  "https://github.rc1844.workers.dev"
  "https://hub.fastgit.xyz"
  "https://hub.njuu.cf"
)
GITHUB_raw=(
  "https://raw.staticdn.net"
  "https://raw.githubusercontents.com"
  "https://raw.fastgit.org"
  "https://ghproxy.com/https://raw.githubusercontent.com"
  "https://raw.kgithub.com"
)

# BMCLAPI mirror list
BMCLAPI_def=(
  "https://bmclapi2.bangbang93.com"
  "https://download.mcbbs.net"
)

BMCLAPI_Assets=(
  "https://bmclapi2.bangbang93.com/assets"
  "https://download.mcbbs.net/assets"
)

BMCLAPI_Maven=(
  "https://bmclapi2.bangbang93.com/maven"
  "https://download.mcbbs.net/maven"
)

BMCLAPI_AI=(
  "https://bmclapi2.bangbang93.com/mirrors/authlib-injector"
  "https://download.mcbbs.net/mirrors/authlib-injector"
)

# Get the domain name and detect whether there is a mirror source
TargetHost=`grep -oP '^[a-z]*?://.*?/' <<< "${URL}"`
if [ -z ${AllowDownloadMirror[${TargetHost%/*}]} ]; then
  DownloadURL=${URL}
else
  MirrorProject=${AllowDownloadMirror[${TargetHost%/*}]};MirrorProject=${MirrorProject%%_*}
  # If there is a mirror source, identify the variables and prepare to synthesize download parameters
  eval "DownloadDomain=(\"\${${AllowDownloadMirror[${TargetHost%/*}]}[@]}\")"
  # Write the source site to the download source list
  DownloadDomain[${#DownloadDomain[@]}]=${TargetHost%/*}
  DownloadURL=`ImageList2DLpara "${DownloadDomain[*]}" "${URL#*${TargetHost}}"`
fi

Thanks ${MirrorProject}

aria2c -c -s 9 -k 3M -o $OUTPUT ${DownloadURL}

Thanks ${MirrorProject}

# Verify the hash value of the downloaded file
if [ ! -z ${MD5}${SHA1}${SHA256} ] ; then
  if [ ! -z ${MD5} ] ; then
    grep -q ${MD1} < <(md5sum ${OUTPUT})
  elif [ ! -z ${SHA1} ] ; then
    grep -q ${SHA1} < <(sha1sum ${OUTPUT})
  elif [ ! -z ${SHA256} ] ; then
    grep -q ${SHA256} < <(sha256sum ${OUTPUT})
  fi
  if [ $? -ne 0 ]; then
    GetI18nText Info_HashCheckFailed "Hash check failed, script has exited";exit 3;
  else
    GetI18nText Info_DownloadHashSucceeded "\e[1;32mFile download and hash check succeeded\e[0m";exit 0;
  fi
else
  GetI18nText Info_DownloadSucceeded "\e[1;34mfile download complete\e[0m";exit 0;
fi

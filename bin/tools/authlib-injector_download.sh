#!/bin/bash

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

DownloadDomain=(
  "https://authlib-injector.yushi.moe"
  "https://bmclapi2.bangbang93.com/mirrors/authlib-injector"
  "https://download.mcbbs.net/mirrors/authlib-injector"
)

DLLink=`curl -s https://bmclapi2.bangbang93.com/mirrors/authlib-injector/artifact/latest.json`
DLLink=${DLLink#*authlib-injector\/}
FileHash=${DLLink#*sha256\": \"};FileHash=${FileHash%\"*}
DLLink=${DLLink%%\"*}
# 合成镜像参数
DownloadURL=`ImageList2DLpara "${DownloadDomain[*]}" "${DLLink}"`
# 下载文件
aria2c -c -s 9 --min-split-size 3M -o authlib-injector.jar ${DownloadURL}
echo "==============================================================================="
# 校验hash
sha256sum authlib-injector.jar | grep ${FileHash} > /dev/null
if [ $? -ne 0 ]; then
  echo "Hash check failed, script has exited";exit 3;
else
  echo "This high -speed download is partially accelerated by the BMCL project to provide some accelerated support"
  echo "File download and hash check succeeded";exit 0;
fi
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

if [ -z "$1" ]; then
  echo The parameter does not exist, please pass in the version number to be queried;
  echo
  echo -e "${0} <Version|latest> "
  echo -e "    Version\tMinecraft server file version"
  exit 1;
fi;
version=$1

DownloadDomain=(
  "http://launcher.mojang.com"
  "https://bmclapi2.bangbang93.com"
  "https://download.mcbbs.net"
)

DLLink=`curl -s https://bmclapi2.bangbang93.com/version/${version}/server`
if [ "$DLLink" == "Not Found" ]; then 
  echo "Version does not exist, script has exited";exit 2;
else
  DLLink=${DLLink#*\/}
  FileHash=${DLLink%\/*};FileHash=${FileHash##*\/}
fi
# 合成镜像参数
DownloadURL=`ImageList2DLpara "${DownloadDomain[*]}" "${DLLink}"`
# 下载文件
aria2c -c -s 9 --min-split-size 3M -o server_${version}.jar ${DownloadURL}
echo "==============================================================================="
# 校验hash
sha1sum server_${version}.jar | grep ${FileHash} > /dev/null
if [ $? -ne 0 ]; then
  echo "Hash check failed, script has exited";exit 3;
else
  echo "This high -speed download is partially accelerated by the BMCL project to provide some accelerated support"
  echo "File download and hash check succeeded";exit 0;
fi
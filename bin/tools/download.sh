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

# 下载对应的文件，并根据列表选择是否启用镜像源下载

# 拥有下载源的功能列表
AllowDownloadMirror=(
  "vanilla"
  "forge"
  "authlib-injector"
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

# BMCL镜像列表
DownloadDomain=(
  "https://bmclapi2.bangbang93.com"
  "https://download.mcbbs.net"
)
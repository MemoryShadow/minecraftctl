#!/bin/bash
if [ -z "$1" ]; then
  echo 参数不存在，请传入需要查询的版本号;
  echo
  echo -e "${0} <Version|latest> [-q]"
  echo -e "    Version\tMinecraft server file version"
  echo -e "    -q\t\tOpen quiet mode:Only show the URL of the latest version of the current query"
  exit 1;
fi;
# 检查：只要参数列表中带有-q，就打开开关
Quiet_F=0
for item in $*
do
  if [ "${item}" == "-q" ]; then
    Quiet_F=1;
    break;
  fi
done
version=$1
# 校验版本是否为关键字，如果是，就自动查询最新版本
if [ "$1" == "latest" ]; then
  version=`curl -s https://papermc.io/api/v2/projects/paper`;version=${version##*,\"};version=${version%%\"*}
fi
if [ ${Quiet_F} == 0 ]; then
  echo ================
  echo 查询目标: paper
  echo 查询版本: ${version}
  echo 检查版本是否存在....
fi
# 校验版本是否存在
curl -s https://papermc.io/api/v2/projects/paper | grep "${version}" > /dev/null
# (0)
if [ $? != 0 ]; then echo 版本不存在,脚本已退出;exit 1;fi
if [ ${Quiet_F} == 0 ]; then echo 版本存在，正在查询最新版本...;fi
# 获取最新构建名称
build=`curl -s https://papermc.io/api/v2/projects/paper/versions/${version}`;build=${build##*,};build=${build%%]*};
if [ ${Quiet_F} == 0 ]; then echo 最新构建的版本为${build},正在拉取文件名...;fi;
# 拉取文件名
filename=`curl -s https://papermc.io/api/v2/projects/paper/versions/${version}/builds/${build}`;filename=${filename##*application\":\{\"name\":\"};filename=${filename%%\"*}
if [ ${Quiet_F} == 0 ]; then echo 文件名为: ${filename};fi;
# 构建URL
FileURL="https://papermc.io/api/v2/projects/paper/versions/${version}/builds/${build}/downloads/${filename}"
if [ ${Quiet_F} == 0 ]; then
  echo 此版本最新的构建文件下载地址为:${FileURL};
  echo ================;
else
  echo ${FileURL};
fi

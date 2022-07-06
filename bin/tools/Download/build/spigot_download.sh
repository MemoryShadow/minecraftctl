#!/bin/bash
###
 # @Date: 2022-07-04 09:47:51
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-06 14:15:27
 # @Description: 
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 
if [ -z "$1" ]; then
  echo The parameter does not exist, please pass in the version number to be queried;
  echo
  echo -e "${0} <Version|latest> "
  echo -e "    Version\tMinecraft server file version"
  exit 1;
fi;

rm -rf /tmp/buildtools
if [! -d /tmp/buildtools ]; then
  mkdir /tmp/buildtools/work
fi
cd /tmp/buildtools/
if [ ! -f BuildTools.jar ] ; then
  wget wget https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
fi;
version=$1
DownloadPara=`bash /opt/minecraftctl/tools/Download/LinkGet.sh -i vanilla -v $version`
bash /opt/minecraftctl/tools/Download/download.sh $DownloadPara -o "./work/minecraft_server.$version.jar"
# 检测java版本

# 构建
java -jar BuildTools.jar -rev $version

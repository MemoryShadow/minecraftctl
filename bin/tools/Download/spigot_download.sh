#!/bin/bash
###
 # @Date: 2022-07-04 09:47:51
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-07-04 14:29:44
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
mkdir -p /tmp/buildtools/work
cd /tmp/buildtools/
wget https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
version=1.18.2
bash /opt/minecraftctl/tools/Download/vanilla_download.sh $version
mv server_$version.jar ./work/minecraft_server.$version.jar

java -jar BuildTools.jar -rev $version

#!/bin/bash
if [ -z "$1" ]; then
  echo The parameter does not exist, please pass in the version number to be queried;
  echo
  echo -e "${0} <Version|latest> [-q]"
  echo -e "    Version\tMinecraft server file version"
  exit 1;
fi;
declare -A versionList=(
  ['1.7.1']=1.7.10
  ['1.7.10']=1.7.10
  ['1.12.2']=1.12.2
  ['1.16.5']=1.16.5
  ['1.18.2']=1.18.2
  ['1.18.2-testing']=1.18.2
)
if [ -z ${versionList[$1]} ]; then
  echo "Version does not exist, script has exited";exit 2;
else
  URL=`curl -s https://mohistmc.com/api/${versionList[$1]}/latest`
  URL=${URL%\",*};URL=${URL%\",*};echo ${URL##*:\"};exit 0;
fi;

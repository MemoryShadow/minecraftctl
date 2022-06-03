#!/bin/bash
if [ -z "$1" ]; then
  echo The parameter does not exist, please pass in the version number to be queried;
  echo
  echo -e "${0} <Version|latest> [-q]"
  echo -e "    Version\tMinecraft server file version"
  exit 1;
fi;
version=$1
# Check whether the version is a keyword, if so, automatically query the latest version
if [ "$1" == "latest" ]; then
  version=`curl -s https://bmclapi2.bangbang93.com/forge/last`;version=${version#*mcversion\":\"};version=${version%%\"*}
else
  # Check if the version exists
  curl -s https://bmclapi2.bangbang93.com/forge/minecraft | grep -w "${version}" > /dev/null
fi
# (0)
if [ $? != 0 ]; then echo Version does not exist, script has exited;exit 2;fi
# Get the latest build name
build=`curl -s https://bmclapi2.bangbang93.com/forge/minecraft/${version}`;build=${build#*\"build\":};
FileHash=${build#*\"hash\":\"};
build=${build%%,*};FileHash=${FileHash%%\"*}
# echo download link
URL=`curl -s "https://bmclapi2.bangbang93.com/forge/download/${build}"`
echo ${URL#*\/} ${FileHash}
exit 0;
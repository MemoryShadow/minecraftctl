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
  version=`curl -s https://papermc.io/api/v2/projects/paper`;version=${version##*,\"};version=${version%%\"*}
  else
  # Check if the version exists
  curl -s https://papermc.io/api/v2/projects/paper | grep -w "${version}" > /dev/null
fi
# (0)
if [ $? != 0 ]; then echo Version does not exist, script has exited;exit 1;fi
# Get the latest build name
build=`curl -s https://papermc.io/api/v2/projects/paper/versions/${version}`;build=${build##*,};build=${build%%]*};
# Get file name
filename=`curl -s https://papermc.io/api/v2/projects/paper/versions/${version}/builds/${build}`;filename=${filename##*application\":\{\"name\":\"};filename=${filename%%\"*}
echo "https://papermc.io/api/v2/projects/paper/versions/${version}/builds/${build}/downloads/${filename}"
exit 0;
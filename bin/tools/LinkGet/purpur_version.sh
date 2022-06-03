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
  version=`curl -s https://api.purpurmc.org/v2/purpur`;version=${version##*,\"};version=${version%%\"*}
  else
  # Check if the version exists
  curl -s https://api.purpurmc.org/v2/purpur | grep -w "$1" > /dev/null
fi
# (0)
if [ $? != 0 ]; then echo Version does not exist, script has exited;exit 2;fi
# Get the latest download URL
echo "https://api.purpurmc.org/v2/purpur/${version}/latest/download?name=purpur-${version}.jar"
exit 0;
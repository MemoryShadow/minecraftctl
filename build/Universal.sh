#!/bin/bash
###
 # @Date: 2022-11-03 09:22:27
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-04-23 09:44:57
 # @Description: 通用安装与卸载(请以root身份运行)
 # Copyright (c) 2022 by MemoryShadow@outlook.com, All Rights Reserved.
### 

if [ -z $1 ]; then
  echo "Usage: $0 [install|uninstall|update]"
  exit 1
fi

MePath=`dirname $0`

if [ "$1" == "uninstall" ]; then
  echo "Uninstalling..."
  cd "${MePath}/../../" 
  # uninstall minecraftctl software(remove the source code directory, installation directory, and the symbolic link)
  rm -rf "${MePath}/../" /opt/minecraftctl /usr/sbin/minecraftctl
  # remove config file
  rm -rf /etc/minecraftctl
  # remove autocomplete file
  rm -rf /etc/profile.d/minecraftctl.sh
  echo "Uninstall complete."
elif [ "$1" == "update" ]; then
  echo "Updating..."
  cd "${MePath}/../"
  git pull
  # uninstall minecraftctl software(remove the source code directory, installation directory, and the symbolic link)
  rm -rf /opt/minecraftctl
  # backup config file
  bash "${MePath}/prerm"
  # install minecraftctl software
  cp -r "${MePath}/../bin" "/opt/minecraftctl"
  # update config file
  bash "${MePath}/postinst"
  echo "Update complete."
elif [ "$1" == "install" ]; then
  echo "Installing..."
  # install minecraftctl
  mkdir /etc/minecraftctl
  cp -r ${MePath}/../etc/* /etc/minecraftctl/
  cp -r ${MePath}/../bin /opt/minecraftctl
  chmod -R 644 /etc/minecraftctl/* /etc/minecraftctl/theme/*
  chmod 755 /etc/minecraftctl /etc/minecraftctl/theme 
  chmod 755 -R /opt/minecraftctl
  # make `sudo` available
  ln -s /opt/minecraftctl/minecraftctl /usr/sbin/minecraftctl
  # register autocomplete
  cat<<EOF>/etc/profile.d/minecraftctl.sh
# minecraftctl autocomplete
_minecraftctl() {
  COMPREPLY=()
  local word="\${COMP_WORDS[COMP_CWORD]}"
  local completions=\$(find /opt/minecraftctl/module/ -name "*.sh" -exec basename {} \; | grep -oe "^[a-zA-Z]*")
  COMPREPLY=( \$(compgen -W "\$completions" -- "\$word") )
}

complete -f -F _minecraftctl minecraftctl

EOF
  echo "Install complete. Log in again or run source /etc/profile to load all features"
else
  echo "Usage: $0 [install|uninstall]"
  exit 1
fi
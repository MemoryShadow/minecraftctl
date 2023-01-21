#!/bin/bash
###
 # @Date: 2022-11-03 08:53:17
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-01-21 20:16:52
 # @Description: 做构建前的准备, 自动生成构建信息, 将文件复制到构建目录
 # Copyright (c) 2022 by MemoryShadow@outlook.com, All Rights Reserved.
###
###
 # 将项目中需要被安装的文件按照目标机的结构复制到指定目录
 # 参数1: 项目路径
 # 参数2: 目标路径
###
function CopyingFiles(){
  mkdir -p ${work_path}/usr/sbin ${work_path}/opt ${work_path}/etc/profile.d
  cp -r ${1}/bin ${2}/opt/minecraftctl
  cp -r ${1}/cfg ${2}/etc/minecraftctl
  cp ${1}/build/complete ${2}/etc/profile.d/minecraftctl.sh
  ln -s /opt/minecraftctl/minecraftctl ${2}/usr/sbin/minecraftctl
  rm -rf ${2}/etc/minecraftctl/i18n
}

# 读取配置信息
MePath=`dirname $0`
pwd_path="${MePath}/.."
source ${MePath}/info
#*生成配置文件目录与信息
# 创建目录
Architecture_T=(${Architecture//,/ })
for Arch in ${Architecture_T[@]}; do
  work_path="${pwd_path}/build/deb/${Arch}"
  mkdir -p ${MePath}/deb/${Arch}/DEBIAN
  cp -r ${MePath}/postinst  ${MePath}/deb/${Arch}/DEBIAN/
  cp -r ${MePath}/prerm  ${MePath}/deb/${Arch}/DEBIAN/
  cp -r ${MePath}/postrm  ${MePath}/deb/${Arch}/DEBIAN/
  cat<<EOF>"${MePath}/deb/${Arch}/DEBIAN/control"
Package: ${Package}
Version: ${Version}
Section: ${Section}
Priority: ${Priority}
Essential: ${Essential}
Source: ${Package}
Architecture: ${Arch}
Depends: ${Depends}
Suggests: ${Suggests}
Installed-Size: ${InstalledSize}
Maintainer: ${Maintainer}[${MaintainerEmail}]
Homepage: ${Homepage}
Description: ${Description}
EOF

CopyingFiles ${pwd_path} ${work_path}

chmod 644 -R ${work_path}/etc/minecraftctl/*
chmod 755 ${work_path}/etc/minecraftctl ${work_path}/etc/minecraftctl/theme
chmod 755 -R ${work_path}/opt/minecraftctl ${work_path}/DEBIAN

done

work_path="${MePath}/rpm/SOURCES"

mkdir -p ${MePath}/rpm/{SPECS,SOURCES}
CopyingFiles ${pwd_path} ${work_path}

cat<<EOF>"${MePath}/rpm/SPECS/minecraftctl.spec"
 #
 # spec file for package ${Package}
 #
 # Copyright (c) ${Maintainer} ${MaintainerEmail}
 #
 # All modifications and additions to the file contributed by third parties
 # remain the property of their copyright owners, unless otherwise agreed
 # upon. The license for this file, and modifications and additions to the
 # file, is the same license as for the pristine package itself (unless the
 # license for the pristine package is not an Open Source License, in which
 # case the license is the MIT License). An "Open Source License" is a
 # license that conforms to the Open Source Definition (Version 1.9)
 # published by the Open Source Initiative.
 
 # Please submit bugfixes or comments via ${Homepage}/issues
 #

Name:		${Package}
Version:	${Version}
Release:	1%{?dist}
Summary:	${Description}

License:	${License}
URL:		${Homepage}

Requires:	${Depends}
BuildRoot:	~/rpmbuild/

%description
${Description}

%prep
################################################################################
# Create the build tree and copy the files from the development directories    #
# into the build tree.                                                         #
################################################################################
echo "BUILDROOT = %{buildroot}"
mkdir -p %{buildroot}/etc/minecraftctl
mkdir -p %{buildroot}/opt/minecraftctl
mkdir -p %{buildroot}/etc/profile.d
cp -r %{_sourcedir}/* %{buildroot}/

%pre
################################################################################
# Pre-installation script                                                      #
################################################################################
EOF
cat "$pwd_path/build/prerm" | sed 's/#!\/bin\/bash/if [ "$1"=="2" ]; then/' >> "${MePath}/rpm/SPECS/minecraftctl.spec"
cat<<EOF>>"${MePath}/rpm/SPECS/minecraftctl.spec"

fi
%post
################################################################################
# Post-installation script                                                     #
################################################################################
EOF
cat "$pwd_path/build/postinst" | sed 's/#!\/bin\/bash/if [ "$1"=="2" ]; then/' >> "${MePath}/rpm/SPECS/minecraftctl.spec"
cat<<EOF>>"${MePath}/rpm/SPECS/minecraftctl.spec"

fi
%postun
################################################################################
# Post-uninstallation script                                                   #
################################################################################
EOF
cat "$pwd_path/build/postrm" | sed 's/#!\/bin\/bash/if [ "$1"=="0" ]; then/' >> "${MePath}/rpm/SPECS/minecraftctl.spec"
cat<<EOF>>"${MePath}/rpm/SPECS/minecraftctl.spec"

fi
%files
%defattr(0644, root, root, 0755)
%attr(0755, root, root) /opt/minecraftctl/*
%attr(0644, root, root) %{_sysconfdir}/minecraftctl/*
%attr(0755, root, root) %{_sysconfdir}/minecraftctl/theme
%attr(0644, root, root) %{_sysconfdir}/profile.d/*
/usr/sbin/minecraftctl

%clean
rm -rf %{buildroot}/*

%changelog
* Mon Nov 21 2022 MemoryShadow <memoryshadow@outlook.com>
  - 重构了此项目
  - 新增install功能, 用于自动安装Minecraft Server
  - 支持自动补全功能
  - Fix: 修复升级时会丢失配置的BUG
  - i18n: 新增多语言支持
EOF
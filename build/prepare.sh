#!/bin/bash
###
 # @Date: 2022-11-03 08:53:17
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-11-06 11:41:04
 # @Description: 做构建前的准备, 自动生成构建信息, 将文件复制到构建目录
 # Copyright (c) 2022 by MemoryShadow@outlook.com, All Rights Reserved.
### 
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

mkdir -p ${work_path}/usr/sbin ${work_path}/{opt,etc}
cp -r ${pwd_path}/bin ${work_path}/opt/minecraftctl
cp -r ${pwd_path}/bin/minecraftctl ${work_path}/usr/sbin/
cp -r ${pwd_path}/cfg ${work_path}/etc/minecraftctl
chmod 644 -R ${work_path}/etc/minecraftctl/*
chmod 755 ${work_path}/etc/minecraftctl ${work_path}/etc/minecraftctl/theme ${work_path}/usr/sbin/minecraftctl
chmod 755 -R ${work_path}/opt/minecraftctl ${work_path}/DEBIAN

done

for Arch in ${Architecture_T[@]}; do
  mkdir -p ${MePath}/rpm/${Arch}/SPECS
    cat<<EOF>"${MePath}/rpm/${Arch}/SPECS/minecraftctl.spec"
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
echo "BUILDROOT = \$RPM_BUILD_ROOT"
mkdir -p \$RPM_BUILD_ROOT/etc/minecraftctl
mkdir -p \$RPM_BUILD_ROOT/usr/sbin

cp -r ~/rpmbuild/cfg/* \$RPM_BUILD_ROOT/etc/minecraftctl/
cp -r ~/rpmbuild/bin/* \$RPM_BUILD_ROOT/usr/sbin/

exit



Package: ${Package}
Version: ${Version}
Section: ${Section}
Priority: ${Priority}
Essential: ${Essential}
Source: ${Package}
Architecture: ${Architecture}
Depends: ${Depends}
Suggests: ${Suggests}
Installed-Size: ${InstalledSize}
Maintainer: ${Maintainer}
Homepage: ${Homepage}
Description: ${Description}
EOF

done
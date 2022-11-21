 #
 # spec file for package minecraftctl
 #
 # Copyright (c) MemoryShadow MemoryShadow@outlook.com
 #
 # All modifications and additions to the file contributed by third parties
 # remain the property of their copyright owners, unless otherwise agreed
 # upon. The license for this file, and modifications and additions to the
 # file, is the same license as for the pristine package itself (unless the
 # license for the pristine package is not an Open Source License, in which
 # case the license is the MIT License). An "Open Source License" is a
 # license that conforms to the Open Source Definition (Version 1.9)
 # published by the Open Source Initiative.
 
 # Please submit bugfixes or comments via https://github.com/MemoryShadow/minecraftctl/issues
 #

Name:		minecraftctl
Version:	1.2.0
Release:	1%{?dist}
Summary:	Minecraft Server control script


License:	GPLv3.0
URL:		https://github.com/MemoryShadow/minecraftctl

Requires:	bash
Requires:	screen,vim,aria2,curl,wget,tar,zip,unzip
BuildRoot:	~/rpmbuild/

%description
Minecraft Server control script

%prep
################################################################################
# Create the build tree and copy the files from the development directories    #
# into the build tree.                                                         #
################################################################################
echo "BUILDROOT = $RPM_BUILD_ROOT"
mkdir -p $RPM_BUILD_ROOT/etc/minecraftctl
mkdir -p $RPM_BUILD_ROOT/usr/sbin

cp -r ~/rpmbuild/cfg/* $RPM_BUILD_ROOT/etc/minecraftctl/
cp -r ~/rpmbuild/bin/* $RPM_BUILD_ROOT/usr/sbin/

exit

%install
#1
# 检查本机是否有配置文件，如果有，就做更新处理
if [ -e "%{_sysconfdir}/minecraftctl/config" ]; then 
  mv /etc/minecraftctl/config /etc/minecraftctl/config.bak
  sed -i "s/\\\$/\\\\\$/g" /etc/minecraftctl/config.bak
  # 加载等待升级的配置文件
  source /etc/minecraftctl/config
  # 如果配置文件存在，就加载旧的配置文件
  if [ -e /etc/minecraftctl/config.bak ]; then
    source /etc/minecraftctl/config.bak
  fi
  # 对旧的配置文件进行兼容性处理(映射)
  cat<<EOF>/etc/minecraftctl/config
  # 游戏文件夹路径
  GamePath="${GamePath}"
  # 会话名(若在修改时任有服务端在运行，会导致残留进程)
  ScreenName="${screen_name:-${ScreenName}}"
  # 启动时内存(MB)
  StartCache=${startCache:-${StartCache}}
  # 最大内存(MB)
  MaxCache=${MaxCache}
  # 你要连接的中转主机的地址是什么
  MasterHost=${MasterHost}
  # 启用SSL(https)?
  HostProtocol=${HostProtocol}
  # 是否忽略可能不安全的链接
  # 如果你的中转主机SSL证书与这个域名不匹配或者不由某官方机构颁发就填true
  Insecure=${Insecure}
  # 是否启用第三方验证
  Authlib=${authlib:-${Authlib}}
  # 第三方验证的验证地址
  AuthlibInjector="${authlib_injectorVer:-${AuthlibInjector}}"
  # 第三方验证器版本
  AuthlibInjectorVer="${authlib_injectorVer:-${AuthlibInjectorVer}}"
  # 第三方验证核心下载地址(下载过慢推荐使用代理地址:https://github.91chi.fun/)
  AuthlibInjectorSoure="${authlib_injectorSoure:-${AuthlibInjectorSoure}}"
  # 服务器启动核心文件名(不含后缀)
  MainJAR="${MainJAR}"
  # 服务器核心,备份文件时使用,支持的值为以下列表
  # 模式名称:等效的值
  # official:official,forge
  # unofficial:unofficial,bukkit,spigot,paper,purpur,airplane
  # 注: 要启用备份配置文件功能请在Backup目录下创建Config文件夹
  ServerCore="${ServerCore}"
  # 备份所使用的线程数量(如果因为线程过多被杀，请调回来)
  BackupThread=${BackupThread}
  # 备份文件的压缩质量(调整至更大会占用相当大的内存空间)
  # 可选的值: 0~9
  BackupCompressLevel=${BackupCompressLevel}
  # 离开时等待的秒数(若是超过此时间服务器还没停止，就会强制杀死进程)
  StopWaitTimeMax=${StopWaitTimeMax}
  EOF

  rm /etc/minecraftctl/config.bak
fi

%files
%attr(0755, root, root) %{_sbindir}/minecraftctl
%attr(0644, root, root) %{_sysconfdir}/minecraftctl/config

%clean
rm -rf $RPM_BUILD_ROOT/etc/minecraftctl
rm -rf $RPM_BUILD_ROOT/usr/sbin
rm -rf ~/rpmbuild/cfg ~/rpmbuild/bin

%changelog
* Wed Jul 21 2021 MemoryShadow <memoryshadow@outlook.com>
  - 将新功能加入帮助手册


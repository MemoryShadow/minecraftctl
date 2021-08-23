Name:		minecraftctl
Version:	1.0.2
Release:	1%{?dist}
Summary:	Minecraft Server control script

License:	GPL
URL:		https://github.com/MemoryShadow/minecraftctl

Requires:	bash
Requires:	screen
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

cp ~/rpmbuild/cfg/* $RPM_BUILD_ROOT/etc/minecraftctl/
cp ~/rpmbuild/bin/* $RPM_BUILD_ROOT/usr/sbin/

exit

%install
#1
# 检查本机是否有配置文件，如果有，就将本机配置文件追加在预备的配置文件末尾来保留配置
if [ -f "%{_sysconfdir}/minecraftctl/config" ]; then 
echo \# The following is the old configuration >> $RPM_BUILD_ROOT/etc/minecraftctl/config
cat %{_sysconfdir}/minecraftctl/config >> $RPM_BUILD_ROOT/etc/minecraftctl/config
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


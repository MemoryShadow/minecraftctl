Name:		minecraftctl
Version:	1.0.1
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


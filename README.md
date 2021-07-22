# 欢迎阅读

一个Minecraft Server管理脚本

## 安装后的部署

此脚本允许接受机器人消息,但是需要您来手动控制消息获取时间

```bash
# 编辑计划任务
crontab -e
# 每隔15秒写入一次
*/1 * * * * /bin/sh /etc/profile;sleep 0;/usr/sbin/minecraftctl QQMsg
*/1 * * * * /bin/sh /etc/profile;sleep 15;/usr/sbin/minecraftctl QQMsg
*/1 * * * * /bin/sh /etc/profile;sleep 30;/usr/sbin/minecraftctl QQMsg
*/1 * * * * /bin/sh /etc/profile;sleep 45;/usr/sbin/minecraftctl QQMsg
```

## 打包

此脚本仅支持Linux,在此处我将示范如何打包为deb格式和rpm格式以在Ubuntu或者CentOS上快速的安装.

### deb格式

```bash
# 克隆仓库
clone https://github.com/MemoryShadow/minecraftctl
# 进入仓库目录
cd minecraftctl/deb
# 创建目录
mkdir -p ./usr/sbin ./etc/minecraftctl
# 将文件内容拷贝至固定目录
cp -f ../bin/minecraftctl ./usr/sbin/
cp -f ../cfg/config ./etc/minecraftctl/
# 调整权限
chmod 755 ./usr/sbin/*
chmod 644 ./etc/minecraftctl/*
# 打包成为deb
dpkg -i . ../minecraftctl_1.0.1_i386.deb
```

### rpm格式

```bash
# 克隆仓库
clone https://github.com/MemoryShadow/minecraftctl
# 安装打包工具
yum install rpmdevtools
# 初始化工作目录
rpmbuild minecraftctl.spec
cd minecraftctl
# 将资源拷贝到用户目录下
cp -r ./bin ~/rpmbuild/
cp -r ./cfg ~/rpmbuild/
cp ./rpm/SPECS/minecraftctl.spec ~/rpmbuild/SPECS/
# 运行构建
rpmbuild --target x86_64 -bb ~/rpmbuild/SPECS/minecraftctl.spec
```

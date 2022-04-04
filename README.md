# 欢迎阅读

一个Minecraft Server管理脚本

此脚本用于帮助运维人员减少重复的操作，帮助他们更加轻松的工作

## 安装后的部署

此脚本允许接受机器人消息,但是需要您来手动控制消息获取时间

```bash
# 编辑计划任务
$crontab -e
```

在打开的文件中写下如下的内容:

```bash
# --------------------------------------------------------
# 每天凌晨的00:10和12:00热备份一次服务器(将会短暂的冻结服务器)
# 启动此计划后,可以将bukkit.yml(如果您是bukkit系服务端)中的autosave字段设为0，可有效避免储存计划的大量IO导致的崩服
10 0 * * * /bin/sh /etc/profile;/usr/sbin/minecraftctl backup
0 12 * * * /bin/sh /etc/profile;/usr/sbin/minecraftctl backup
# 每隔15秒写入一次,并要求不发送邮件,避免邮件过多
*/1 * * * * /bin/sh /etc/profile;sleep 0;/usr/sbin/minecraftctl QQMsg >/dev/null 2>/dev/null
*/1 * * * * /bin/sh /etc/profile;sleep 15;/usr/sbin/minecraftctl QQMsg >/dev/null 2>/dev/null
*/1 * * * * /bin/sh /etc/profile;sleep 30;/usr/sbin/minecraftctl QQMsg >/dev/null 2>/dev/null
*/1 * * * * /bin/sh /etc/profile;sleep 45;/usr/sbin/minecraftctl QQMsg >/dev/null 2>/dev/null
# --------------------------------------------------------
```

## 打包

此脚本仅支持Linux,在此处我将示范如何打包为deb格式和rpm格式以在Ubuntu或者CentOS上快速的安装.

### deb格式

```bash
# 克隆仓库
git clone git://github.com/MemoryShadow/minecraftctl
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
git clone git://github.com/MemoryShadow/minecraftctl
# 安装打包工具
yum install rpmdevtools
# 初始化工作目录
mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
# 也可以使用下面这句,会出现一次报错,实际上已经初始化好了
# rpmbuild minecraftctl.spec
cd minecraftctl
# 将资源拷贝到用户目录下
cp -r ./bin ~/rpmbuild/
cp -r ./cfg ~/rpmbuild/
cp ./rpm/SPECS/minecraftctl.spec ~/rpmbuild/SPECS/
# 运行构建
rpmbuild --target x86_64 -bb ~/rpmbuild/SPECS/minecraftctl.spec
```

### TODO
- [ ] 写minecraftctl的存档切换功能
- [ ] 写minecraftctl-install命令
  - [ ] 支持官方服务端下载地址查询/获取
      ```bash
      # 或许我可以用这个
      echo `curl -s https://mcversions.net/download/1.12.2 | xmllint --html --xpath '//div[@class="downloads block lg:flex lg:mt-0 p-8 md:p-12 md:pr-0 lg:col-start-1"]/div[1]/a/@href' - 2> /dev/null`
      ```
  - [ ] 支持Bukkit下载地址查询/获取
  - [ ] 支持Spigot自动构建部署
  - [x] 支持Paper下载地址查询/获取
  - [ ] 支持Mohist下载地址查询/获取
  - [ ] 支持airplane下载地址查询/获取
  - [ ] 支持Sponge下载地址查询/获取
- [ ] 写minecraftctl用户消息获取功能
- [ ] 写minecraftctl的简单UI界面

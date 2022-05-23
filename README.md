# minecraftctl

这是一套Minecraft Server管理脚本

此脚本用于帮助运维人员减少重复的操作，帮助他们更加轻松的工作

## 目录

- [minecraftctl](#minecraftctl)
  - [目录](#目录)
  - [说明](#说明)
  - [构建包管理器安装包](#构建包管理器安装包)
    - [deb](#deb)
    - [rpm](#rpm)
  - [安装](#安装)
    - [安装deb软件包](#安装deb软件包)
    - [安装rpm软件包](#安装rpm软件包)
    - [Linux通用安装](#linux通用安装)
  - [使用说明](#使用说明)
    - [安装后的部署](#安装后的部署)
  - [用法示例](#用法示例)
  - [相关仓库](#相关仓库)
  - [维护者](#维护者)
  - [如何贡献](#如何贡献)
  - [展望未来](#展望未来)
  - [使用许可](#使用许可)

## 说明

这是一套Minecraft Server管理脚本

此脚本用于帮助运维人员减少重复的操作，帮助他们更加轻松的工作

[![GitHub](https://img.shields.io/github/license/MemoryShadow/minecraftctl)](LICENSE "查看协议")
[![Build/release](https://github.com/MemoryShadow/minecraftctl/actions/workflows/AutoReleases.yml/badge.svg?branch=master)](https://github.com/MemoryShadow/minecraftctl/actions/workflows/AutoReleases.yml)
[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg)](https://github.com/RichardLitt/standard-readme)
[![GitHub release (latest by date)](https://img.shields.io/github/downloads/MemoryShadow/minecraftctl/latest/total)](https://github.com/MemoryShadow/minecraftctl/releases/latest)


## 构建包管理器安装包

### deb

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

### rpm

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

## 安装

这个项目使用 [screen](https://www.gnu.org/software/screen/ "点击查看") 和 [aric2](https://github.com/aria2/aria2 "这是计划中的依赖，后续为加速下载提供支持")。请确保你本地安装了它们。

```bash
sudo yum/apt-get install screen aria2
```

### 安装deb软件包

```bash
sudo apt install minecraftctl*.deb
```

### 安装rpm软件包

```bash
sudo rpm -i minecraftctl*.rpm
```

### Linux通用安装

`注意: 使用此方案将会导致您失去包管理器的管理，但您能以最快的速度体验到最新的支持(相当于alpha版本)`

~~在master分支滚动更新的我是屑~~

```bash
git clone --depth 1 -b master https://github.com/MemoryShadow/minecraftctl.git
sudo mkdir /usr/bin/minecraftctl /etc/minecraftctl
sudo cp -r minecraftctl/bin/* /usr/bin/minecraftctl/
sudo cp -r minecraftctl/cfg/* /etc/minecraftctl/
sudo chmod -R 755 /usr/bin/minecraftctl/ /etc/minecraftctl
sudo chmod -R 644 /etc/minecraftctl/*
sudo ln /usr/bin/minecraftctl/minecraftctl /usr/bin/minecraftctl
rm -rf minecraftctl
```

## 使用说明

后端代码正在逐渐剥离中，请先暂时联系我注册

### 安装后的部署

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

## 用法示例

```bash
[hostname@username ~]$ minecraftctl help
此脚本用于以尽可能简洁的方式对Minecraft服务端进行控制
minecraftctl <功能名称> [可能的参数]

        restart 重启服务器
        backup  备份服务器(如果已经存在实例，就会进行紧急备份)
        start   启动服务器
        QQMsg   服务器接收QQ消息
        stop [理由]
                关闭服务器
        join    此功能用于连接后台
        edit [cfg|ser|op|wh|sp]
                编辑文档功能
        view    打开一个多会话的页面，使得后台终端不再处于独占模式(beta)
        --h help        此功能用于获取帮助文档
        say <要发送的消息> [要模拟的ID] 向服务器发送消息

```

## 相关仓库

- [screen](https://git.savannah.gnu.org/cgit/screen.git) — 一个优秀的会话管理工具
- [aric2](https://github.com/aria2/aria2) — 一个支持多线程和多协议的下载程序 `这是计划中的依赖，后续为加速下载提供支持`

## 维护者

[@MemoryShadow](https://github.com/MemoryShadow)

## 如何贡献

非常欢迎你的加入！[提一个 Issue](https://github.com/MemoryShadow/minecraftctl/issues/new) 或者提交一个 Pull Request。

标准 Readme 遵循 [Contributor Covenant](http://contributor-covenant.org/version/1/3/0/) 行为规范。

## 展望未来

详见[Issues · 鸽子画饼](https://github.com/MemoryShadow/minecraftctl/issues/3 "点击前往")

## 使用许可

[GPL-3.0](LICENSE) © MemoryShadow

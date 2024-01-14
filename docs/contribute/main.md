# minecraftctl 开发文档

欢迎您的参与 :heart: :heart: :heart:, 本文将会帮助您完成在 `minecraftctl` 的开发前置工作。

阅读并跟随此文档, 您将获得一个完整的 minecraftctl 开发环境.

## 目录

- [minecraftctl 开发文档](#minecraftctl-开发文档)
  - [目录](#目录)
  - [初始环境](#初始环境)
    - [操作系统](#操作系统)
    - [编辑器环境](#编辑器环境)
    - [依赖项](#依赖项)
      - [RedHat系](#redhat系)
      - [Debian系](#debian系)
      - [ArchLinux系](#archlinux系)
  - [开发与测试环境](#开发与测试环境)

## 初始环境

- 操作系统: Linux 任一发行版, 在本例中将使用 Arch Linux 进行演示.
- 编辑器环境: 您使用任何您熟悉的编辑器即可, 本文将使用[Visual Studio Code](https://code.visualstudio.com/)编辑器进行演示.
- 依赖项(通常使用包管理器即可安装): sudo,git,bash,screen,vim,aria2,curl,tar,zip,unzip,wget,git

### 操作系统

由于本项目转为类 Unix 系统设计, 为性能优化使用了不少该系统的特性, 故此开发与测试工作也同样需要在一个类 Unix 系统上进行.

### 编辑器环境

本项目所使用的语言为非编译型语言, 由于不需要编译, 因此只需要使用任意一个编辑器即可, 例如: Visual Studio Code, vim, emacs 等, 推荐支持高亮.

### 依赖项

本项目在开发, 运行, 调试过程中使用的依赖项均一致. 这里给出一些常见操作系统上的快速安装命令, 如果希望补充, 请参见README的"如何贡献"章节.

#### RedHat系

```bash
yum install sudo git bash screen vim aria2 curl tar zip unzip wget git
```

#### Debian系

```bash
apt-get install sudo git bash screen vim aria2 curl tar zip unzip wget git
```

#### ArchLinux系

```bash
pacman -S sudo git bash screen vim aria2 curl tar zip unzip wget git
```

## 开发与测试环境

以root身份执行下方命令即可

```bash
git clone https://github.com/MemoryShadow/minecraftctl.git
git clone https://github.com/minecraftctl/I18N.git minecraftctl_i18n
ln -s `pwd`/minecraftctl_i18n/i18n `pwd`/minecraftctl/etc/i18n
cd minecraftctl
ln -s `pwd`/bin /opt/minecraftctl
ln -s `pwd`/etc /etc/minecraftctl
ln -s /opt/minecraftctl/minecraftctl /usr/bin/minecraftctl
```

minecraftctl 现在是由志愿者维护的项目, 我们欢迎且鼓励您加入我们.

谢谢 :heart: :heart: :heart:

MemoryShadow

# Optimize

优化相关 :

* [从系统的选择优化](#optimizing-from-the-selection-os "请尽可能选择Linux无GUI的版本")
* [从Java的选择优化](#optimizing-from-the-choice-of-java "请选择j9版本")
* [从启动参数优化](#optimize-from-startup-parameters "点击查看")
* [从配置文件优化](#optimize-from-configuration-file "点击查看")
  * [通过server.properties优化](#optimized-through-serverproperties "点击查看")
  * [通过第三方核心配置优化](#optimized-through-third-party-core-configuration "点击查看")
    * [bukkit](#bukkit "点击查看")
    * [spigot](#spigot "点击查看")
    * [paper](#paper "点击查看")


## Optimizing from the selection OS

`从系统的选择优化`

通常，我们作为服务器的操作系统有两种，但是也不排除有人使用废弃的MacBook来作为服务器，所以我们将从这三个系统当中介绍他们的优劣，并给出我们的推荐:**`请尽可能选择Linux无GUI的版本`**。

<details>
<summary>优劣表</summary>

|条目/系统|Windows Server|Linux|更好的选择
|---|---|---|---
|开箱带有GUI|:heavy_check_mark:|:x:|Windows Server
|社区支持是否丰富|:heavy_check_mark:|:heavy_check_mark:|平分秋色
|是否可以脱离GUI工作|:x:|:heavy_check_mark:|Linux
|是否支持SSH连接|:x:|:heavy_check_mark:|Linux
|GUI崩溃是否导致系统崩溃|:heavy_check_mark:|:x:|Linux
|是否支持Docker|:x:|:heavy_check_mark:|Linux
|是否开源|:x:|:heavy_check_mark:|Linux
|需要付费|:heavy_check_mark:|:x:|Linux
|安装软件是否方便(可否自动化完成)|:x:|:heavy_check_mark:|Linux
|便于上手|:heavy_check_mark:|:x:|Windows Server

</details>

### Windows Server

这或许是市场上占有率最高的操作系统了，但这并不是我们作为一个服务器系统的首选。

### Linux

一般来说，这是我们选择服务器的最佳选择。

#### CentOS

`CentOS是Linux的一个分支,是Red Hat Enterprise Linux的再编译版本,可靠性和稳定性极高`

但是CentOS即将失去支持,所以建议使用CentOS7作为服务器操作系统

#### Ubuntu

`Ubuntu是一个以桌面应用为主的操作系统,它为了桌面环境付出了很多的代价.`

不建议作为服务器系统

### Optimizing from the choice of Java

`从Java的选择优化`

目前主流的两种Java的实现是j9和hotspot

我们这里选择J9,因为从某些方面来讲，它会更"快"一些,我们后续的优化都将围绕J9这个实现来开展

### Optimize from startup parameters

`从启动参数优化`

```bash
java -server -Xmx最大内存M -Xms最小内存M -Xss512K -Xaggressive -Xalwaysclassgc [-XcompilationThreads4] -Xconmeter:dynamic [-Xgcpolicy:metronome] -Xshareclasses [-Xtune:virtualized] -jar <xxx.jar>
```

<details>
<summary>参数含义</summary>

|参数|含义|示例
|---|---|---
|-server|服务器运行模式，为持久运行优化|java -server <xxx.jar>
|-Xms|初始堆大小，一般是物理内存的1/64(<1GB)，和-Xmx一样大可以节省一点CPU资源|java -Xms1024M <xxx.jar>
|-Xmx|最大堆大小，一般是物理内存的1/4(<1GB)，不过MC服务端对于内存的要求挺高的，能用上的都用上吧|java -Xmx2048M <xxx.jar>
|-Xss|每个线程的堆栈大小，OpenJ9默认是1024KB，不过另一位服主的帖指出，对于MC，512KB足够了|java -Xss512K <xxx.jar>
|-Xaggressive|更激进的性能优化，OpenJ9的文档指出它会在未来版本作为默认选项|java -Xaggressive <xxx.jar>
|-Xalwaysclassgc|始终在全局垃圾回收期间执行动态类卸载检查，减少内存占用|java -Xalwaysclassgc <xxx.jar>
|-XcompilationThreads4|指定JIT编译器使用的编译线程数，最高只能设到4，如果服务器物理核心不足4个，设置成物理核心的一半|java -XcompilationThreads4 <xxx.jar>
|-Xconmeter:dynamic|动态检测大对象区或小对象区域的使用情况|java -Xconmeter:dynamic <xxx.jar>
|-Xgcpolicy:metronome|启用metronome垃圾收集器，可以让垃圾收集时的瞬卡更短暂。仅支持AIX(没人用这个开MC服吧)和Linux，Windows就不要加了。|java -Xgcpolicy:metronome <xxx.jar>
|-Xshareclasses|OpenJ9的高速类共享功能，减少内存占用与启动时间，适合多个JVM运行相似代码的环境，或定期重启JVM的环境，对于群组服非常有用。|java -Xshareclasses <xxx.jar>
|-Xtune:virtualized|假如你的服务器运行在虚拟化环境中(例如阿里云、腾讯云等等)，使用这一选项可以在空闲时减少OpenJ9 VM CPU消耗，有可能会略微提升性能与减少内存占用，不过代价是吞吐量的少量损失。实体机环境不要加! |java -Xtune:virtualized <xxx.jar>
|-XX:+AggressiveOpts|尽可能的使用更多对性能有帮助的优化功能|java -XX:+AggressiveOpts <xxx.jar>
|-XX:+UseCompressedOops|指针压缩，可以减少一定的内存占用(64位才支持)|java -XX:+UseCompressedOops <xxx.jar>

</details>

### Optimize from configuration file

`从配置文件优化`

上述的优化选择只是一小部分的优化，还有更多的优化可以在配置文件中做到

#### Optimized through server.properties

`通过server.properties优化`

参阅: [server.properties - Minecraft Wiki，最详细的官方我的世界百科](https://minecraft.fandom.com/zh/wiki/Server.properties "点击前往")

|条目|作用|建议|可输入的值|默认
|---|---|---|---|---
|view-distance|视距|4-6|int|10
|generate-structures|生成特殊结构|无|boolean|true

#### Optimized through third-party core configuration

`通过第三方核心配置优化`

##### bukkit

`配置bukkit.yml来优化服务器`

参阅: [Bukkit.yml - BukkitWiki](https://bukkit.fandom.com/wiki/Bukkit.yml "点击前往")

由于Bukkit.yml文档结构较为特殊，此文档中只标记了需要关注的父项，具体的配置请点击链接查看文档

|条目|作用|建议|可输入的值|默认
|---|---|---|---|---
|[spawn-limits](https://bukkit.fandom.com/wiki/Bukkit.yml#spawn-limits "查看")|决定每个世界可以生成多少动物或生物
|[chunk-gc](https://bukkit.fandom.com/wiki/Bukkit.yml#chunk-gc "查看")|CraftBukkit 将检查本应卸载但由于某种原因未能这样做的块
|[ticks-per](https://bukkit.fandom.com/wiki/Bukkit.yml#ticks-per "查看")|确定特定功能的滴答延迟|此处需要关注的是子项autosave,将这个选项设为0然后手动控制,将会避免突如其来的IO跑满引起的服务器崩溃

##### spigot

`配置spigot.yml来优化服务器`

参阅: [spigot.yml Konfiguration | SpigotMC - High Performance Minecraft](https://www.spigotmc.org/wiki/spigot-yml-konfiguration/ "点击前往")

|条目|作用|建议|可输入的值|默认
|---|---|---|---|---
|save-user-cache-on-stop-only|是否仅在开关服务器时才保存玩家信息|true|boolean|false
|view-distance|控制将在每个玩家周围加载的区块数量|4-6|1-15,int|10
|chunks-per-tick|是指每tick（1/20秒）扫描计算多少区块，计算的内容是作物的生长|350|int|650
|max-tick-time|在服务器跳到下一个任务之前，（平铺）实体操作可以消耗的时间（以毫秒为单位）进行计算|tile:10-20,entity:20-25|int|tile: 50, entity: 50
|max-tnt-per-tick|每tick（1/20秒）最多计算多少TNT爆炸|20|int|20

##### paper

`配置paper.yml来优化服务器`

|条目|作用|建议|可输入的值|默认
|---|---|---|---|---
|keep-spawn-loaded|spawn区块是否常驻内存|false|boolean|true
|optimize-explosions|是否开启爆炸算法优化|true|boolean|false

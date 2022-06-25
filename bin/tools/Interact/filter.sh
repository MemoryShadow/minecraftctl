#!/bin/bash
#*在工作切片结束时检查是否已经超时(WorkSecond),如果超时就休眠指定的秒数,如果达成WorkPart超过WorkExceedSecond指定的秒数就不进入休眠直接进入下一轮(因为这意味着几乎没有额外性能损耗)
# TODO 优化1: 消息按分的片整体发送, 避免频繁echo带来的高额IO开销
# TODO 优化2: 额外的解析功能按异步进行处理，避免堵塞

source /etc/minecraftctl/config

# 初始化工作
if [ $# -gt 0 ];then
    exec 0<$1;    #将文件绑定到标准输入（0-标准输入 1-标准输出 3-标准错误），默认第一个参数是输入的文件；
fi

# 存储任务完成的数量
WorkPartIndex=${WorkPart}
# 记录好任务开始时的时间戳
Timestamp=$((`date '+%s'`))

# 循环取读终端中的内容
while read line
do
  # 刹车机制
  if [ ${WorkPartIndex} -gt ${WorkPart} ] && [ $((`date '+%s'`-$WorkSecond)) -gt ${Timestamp} ]; then
    if [ ${Timestamp} -gt $((`date '+%s'`-$WorkExceedSecond)) ]; then
      sleep ${SleepSecond}
    fi
    WorkPartIndex=0
    Timestamp=$((`date '+%s'`))
  else
    WorkPartIndex=$((${WorkPartIndex}+1))
  fi
  # 在这里处理额外的显示
  # 检查是否为玩家说话，如果是，就做处理(这里只匹配是为了不损坏原始消息)
  echo $line | grep -e '^\[[0-9:]\{0,8\}\] \[Server thread\/INFO\]: <[0-9a-zA-Z ]*> .*$' > /dev/null
  if [ $? -eq 0 ]; then
    # 删去无用的信息
    str=`echo $line | sed 's/^\[[0-9:]\{0,8\}\] \[Server thread\/INFO\]: <//'`
    # 取出玩家名和玩家说的话
    PlayerName=${str%%\>*}
    PlayerMessage=${str#*> }
    # 检查玩家消息是否以!!qq开头，如果是，就去掉该关键字并在后台留下一句话
    echo $PlayerMessage | grep -e '^!!qq' > /dev/null
    if [ $? -eq 0 ]; then
      echo 玩家 ${PlayerName} 试图向QQ群发送: ${PlayerMessage#*\!\!qq }
    fi
  fi
  # 在这里无条件正常回显终端内容
  echo $line;
done<&0;    #从标准输入读取数据
exec 0<&-   #关闭标准输出。（是否也意味着解除之前的文件绑定？？）

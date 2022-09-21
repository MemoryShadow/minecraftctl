#!/bin/bash
###
 # @Date: 2022-07-23 20:45:10
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2022-09-19 19:55:14
 # @Description: 倾听传入的信息,并执行相应的操作
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 
#*在工作切片结束时检查是否已经超时(WorkSecond),如果超时就休眠指定的秒数,如果达成WorkPart超过WorkExceedSecond指定的秒数就不进入休眠直接进入下一轮(因为这意味着几乎没有额外性能损耗)
# TODO 优化1: 消息按分的片整体发送, 避免频繁echo带来的高额IO开销
# TODO 优化2: 额外的解析功能按异步进行处理，避免堵塞

source $InstallPath/tools/Base.sh

#* show this help menu
function helpMenu() {
  GetI18nText Help_module_Introduction "Listen to incoming information and take appropriate action"
  if [[ ! -z $1 && "$1" == "mini" ]]; then return 0; fi
  GetI18nText Help_module_usage "Usage: minecraftctl listen [-h[mini]]"
  return 0;
}

ARGS=`getopt -o h:: -l help:: -- "$@"`
if [ $? != 0 ]; then
  helpMenu > /dev/stderr;exit 1;
fi

# Assign normalized command line arguments to positional arguments($1,$2,...)
eval set -- "${ARGS}"

while true
do
  case "$1" in
    -h|--help)
      helpMenu "$2"
      exit $?
      ;;
    --)
      shift
      break
      ;;
    *)
      GetI18nText Error_Internal "Internal error!" > /dev/stderr;
      exit 1
      ;;
  esac
done

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
  # 去除颜色信息, 方便后续解析信息
  line_str=`echo "$line" | sed 's/[[:cntrl:]]\[[0-9;?]*[mhlK]//g' | sed 's/[[:cntrl:]]//g'`
  # 检查是否为玩家说话，如果是，就做处理(这里只匹配是为了不损坏原始消息)
  echo "$line_str" | grep -P '^(> )?\[[0-9:]{0,8}.*?[ \/]INFO\]: <[0-9a-zA-Z ]*> .*$'
  if [ $? -eq 0 ]; then
    echo "[Debug@Listen] 是一条玩家消息" > /dev/stderr
    # 删去无用的信息
    str=`echo "$line_str" | sed -E 's/^(> )?\[[0-9:]{0,8}.*?[ \/]INFO\]: <//'`
    # 取出玩家名和玩家说的话
    echo "[Debug@Listen] 取出玩家名和玩家说的话: $str" > /dev/stderr
    PlayerName="${str%%\>*}"
    PlayerMessage="${str#*> }"
    echo "[Debug@Listen] 玩家是$PlayerName, 内容是$PlayerMessage" > /dev/stderr
    # 检查玩家消息是否以!!qq开头，如果是，就去掉该关键字并在后台留下一句话
    echo "$PlayerMessage" | grep -e '^!!qq' > /dev/null
    if [ $? -eq 0 ]; then
      echo -e "\e[1;35m玩家 \e[1;34m${PlayerName} \e[1;35m试图向QQ群发送: \e[1;32m${PlayerMessage#*\!\!qq }\e[0m"
    fi
  fi
  # 在这里无条件正常回显终端内容
  echo "$line";
done<&0;    #从标准输入读取数据
exec 0<&-   #关闭标准输出。（是否也意味着解除之前的文件绑定？？）

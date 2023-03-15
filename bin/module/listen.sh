#!/bin/bash
###
 # @Date: 2022-07-23 20:45:10
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-03-11 12:46:30
 # @Description: 倾听传入的信息,并执行相应的操作
 # Copyright (c) 2022 by MemoryShadow MemoryShadow@outlook.com, All Rights Reserved. 
### 
#*在工作切片结束时检查是否已经超时(WorkSecond),如果超时就休眠指定的秒数,如果达成WorkPart超过WorkExceedSecond指定的秒数就不进入休眠直接进入下一轮(因为这意味着几乎没有额外性能损耗)
# TODO 优化1: 消息按分的片整体发送, 避免频繁echo带来的高额IO开销(主要是锁竞争)
# TODO 优化2: 额外的解析功能按异步进行处理，避免堵塞

source $InstallPath/tools/Base.sh

# 建立相互的关系

declare -A EventTypes=(
  ['INFO']='^(> )?\[[0-9:]{0,8}.*?[ \/]INFO\]: '
)


declare -A EventINFO=(
  ['msg']='<[0-9a-zA-Z ]*> .*$'
  ['login']='[0-9a-zA-Z ]* joined the game$'
  ['logout']='[0-9a-zA-Z ]* left the game$'
  ['start']=' ?\([0-9]\.[0-9]*s\)[！!].*["“]/?help["”]'
  ['stop']='(Stopping server)|(关闭服务器中)'
)


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
# 临时存储数组, 用于暂存每行的内容
declare -A line_PlainText=(
  ['original']=''
  ['prefix']=''
  ['content']=''
  ['EventType']=''
  ['EventTarget']=''
)

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
  
  line_PlainText['original']=`sed 's/[[:cntrl:]]\[[0-9;?]*[mhlK]//g' <<< "${line}" | sed 's/[[:cntrl:]]//g'`
  for EventType in "${!EventTypes[@]}"; do
    grep -qP "${EventTypes[$EventType]}" <<< "${line_PlainText[original]}"
    if [ $? -eq 0 ]; then
      line_PlainText[EventType]=$EventType
      # 将Event映射到对应的事件源去作为当前事件供后续处理, EventXXXX->Event
      temp=`declare -p Event$EventType`
      eval "${temp/Event${EventType}=/Event=}"
      unset temp

      # 删去前缀信息
      line_PlainText['prefix']=`grep -oP "${EventTypes[$EventType]}" <<< "${line_PlainText[original]}"`
      # 取出主体内容
      line_PlainText['content']=${line_PlainText[original]#*${line_PlainText[prefix]//\]/\\]}}
      # 将此信息与Event对应的数组进行匹配以得到事件的转发源
      for EventTarget in "${!Event[@]}"; do
        grep -qP "${Event[$EventTarget]}" <<< "${line_PlainText[content]}"
        if [ $? -eq 0 ]; then
          # 将消息异步发送给对应的数据
          "${InstallPath}/event/${EventType}/${EventTarget}" "${line_PlainText[content]}"
        fi
      done
    fi
  done
  # 在这里无条件正常回显终端内容
  echo "$line";
done <&0;    #从标准输入读取数据
exec 0<&-   #关闭标准输出。（是否也意味着解除之前的文件绑定？？）

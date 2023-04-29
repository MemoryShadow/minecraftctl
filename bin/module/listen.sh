#!/bin/bash
###
 # @Date: 2022-07-23 20:45:10
 # @Author: MemoryShadow
 # @LastEditors: MemoryShadow
 # @LastEditTime: 2023-04-29 17:54:15
 # @Description: 倾听传入的信息,并执行相应的操作
 # Copyright (c) 2022 by MemoryShadow@outlook.com, All Rights Reserved. 
### 
#*在工作切片结束时检查是否已经超时(WorkSecond),如果超时就休眠指定的秒数,如果达成WorkPart超过WorkExceedSecond指定的秒数就不进入休眠直接进入下一轮(因为这意味着几乎没有额外性能损耗)
# TODO 优化1: 消息按分的片整体发送, 避免频繁echo带来的高额IO开销(主要是锁竞争)

source $InstallPath/tools/Base.sh

# 子进程数据信息(保存在内存中)
declare -A Subprocess=(
  ['Infos']=''
)

# 处理子进程的自动事件, 将已结束的进程从记录中筛去, 将超时子进程杀死
#?@param1: 子进程列表, 时间戳和PID由逗号分隔, 不同记录之间使用空格分割
function SubprocessAuto() {
  CommandMaxRun=${CommandMaxRun:-5}
  local NowTime=`date +%s`
  local SubprocessInfos=(${1// / })
  local NextSubprocessInfos=''
  # 遍历子进程列表
  for SubprocessInfo in $1; do
    SubprocessInfo=(${SubprocessInfo//,/ })
    local SubprocessTime=$((NowTime-SubprocessInfo[0]))
    local SubprocessPID=${SubprocessInfo[1]}
    # 检查当前进程是否还存在, 如果存在就将其写入NextSubprocessInfos
    if [ -d "/proc/${SubprocessPID}" ]; then
      if [ $SubprocessTime -gt $CommandMaxRun ]; then
        # 超时了就杀掉
        kill ${SubprocessPID}
      else
        # 子进程还存在且没有超时, 就将其写入当前缓存信息
        NextSubprocessInfos="${NextSubprocessInfos:+${NextSubprocessInfos} }${subprocessInfo}";
      fi
    fi
  done
  Subprocess['Infos']="${NextSubprocessInfos}"
}

# 多线程组件交互通讯机制
# 这其中, 3: 进程信息, 4: command事件标准输出信息(会显示到游戏内), 5: command事件错误输出信息(只会显示在控制台)
#?@param1: 要进行的操作, 允许的值为: Init, Close
function PIPE() {
  local FIFO_Min=3
  local FIFO_Sum=3
  case "${1}" in
  Init)
    # 创建命名管道存放的位置
    mkdir -p /tmp/minecraftctl/FIFO
    # 在首次运行时创建若干个FIFO以进行通讯
    for i in $(seq $FIFO_Min $[FIFO_Min + FIFO_Sum - 1]); do
      [ -e "/tmp/minecraftctl/FIFO/${i}.fifo" ] || mkfifo "/tmp/minecraftctl/FIFO/${i}.fifo"
      [[ `ls -l /proc/$$/fd | grep "${i}.fifo" | awk '{print $8}'` == ${i} ]] || eval "exec ${i}<> '/tmp/minecraftctl/FIFO/${i}.fifo'"
    done
    # ls -l /proc/$$/fd | grep ".fifo"
    # echo -e "123\n456\n789">&4
    ;;
  Close)
    for i in $(seq $FIFO_Min $[FIFO_Min + FIFO_Sum - 1]); do
      [[ `ls -l /proc/$$/fd | grep "${i}.fifo" | awk '{print $8}'` == ${i} ]] && exec {i}<&-
    done
    ;;
  esac
}

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

while true; do
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
if [ $# -gt 0 ]; then
  exec 0<$1;    #将文件绑定到标准输入（0-标准输入 1-标准输出 3-标准错误），默认第一个参数是输入的文件；
fi
# 初始化线程池
PIPE Init

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
while read line; do
  # 刹车机制: 当在WorkSecond秒内终端输出了超过WorkExceedSecond条语句, 就暂停处理SleepSecond秒来避免恶意占用CPU.
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
          # 将消息异步发送给对应的事件
          source "${InstallPath}/event/${EventType}/${EventTarget}" "${line_PlainText[content]}"
        fi
      done
    fi
  done
  # 在这里无条件正常回显终端内容
  echo "$line";
  # 非堵塞读取一条子进程信息(3)并处理(因为一条语句最多出现一个子进程)
  if read -u3 -t 0.01 subprocessInfo; then
    Subprocess['Infos']="${Subprocess[Infos]:+${Subprocess[Infos]} }${subprocessInfo}";
    SubprocessAuto "${Subprocess[Infos]}"
  fi
  # 非堵塞读取来自命令的标准输出(4)并处理
  while true; do
    if read -u4 -t 0.01 commandOut; then
      # 读到数据后在这里处理(显示在终端和服内)
      echo "[commandOut@Listen]: $commandOut" > /dev/stderr
      cmd2server "tellraw @a \"`sed 's/[[:cntrl:]]\[[0-9;?]*[mhlK]//g' <<< "${commandOut}" | sed 's/[[:cntrl:]]//g'`\""
    else break; # 内容已读完
    fi
  done
  # 非堵塞读取来自命令的错误输出(5)并处理
  while true; do
    if read -u5 -t 0.01 commandErrOut; then
      # 读到数据后在这里处理
      echo "[commandErrOut@Listen]: $commandErrOut" > /dev/stderr
    else break; # 内容已读完
    fi
  done
done <&0;    #从标准输入读取数据

wait
# 初始化线程池
PIPE Close
exec 0<&-   #关闭标准输出。（是否也意味着解除之前的文件绑定？？）

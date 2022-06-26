#!/bin/bash
#*************************************************************
#Author:    yangruitao
#Date:      2020-11-04
#FileName:  color.sh
#Source:    https://cloud.tencent.com/developer/article/1756202
#*************************************************************
black="0"
red="1"
green="2"
yellow="3"
blue="4"
magenta="5"
cyan="6"
white="7"

# Color 为文本和背景设置颜色
function Color() {
    Content=""
    Fg="3$1"
    Bg="4$2"
    SetColor="\e[$Fg;${Bg}m "
    EndColor=" \e[0m"
    for((i=3;i<=$#;i++)); do
        j=${!i}
        Content="${Content} $j "
    done
    echo -e ${SetColor}${Content}${EndColor}
}

# echo_black 输出黑色文本 可加背景颜色参数(背景默认不设置)
function echo_black() {
    if [ "$1" == "-b" ]; then
        Bg=$(($2))
        Content=$3
    else
        Bg="8"
        Content=$1
    fi
    Color $black $Bg $Content
}

# echo_red 输出红色文本 可加背景颜色参数(背景默认不设置)
function echo_red() {
   if [ "$1" == "-b" ]; then
        Bg=$(($2))
        Content=$3
    else
        Bg="8"
        Content=$1
    fi
    Color $red $Bg $Content
}

# echo_green 输出绿色文本 可加背景颜色参数(背景默认不设置)
function echo_green() {
    if [ "$1" == "-b" ]; then
        Bg=$(($2))
        Content=$3
    else
        Bg="8"
        Content=$1
    fi
    Color $green $Bg $Content
}

# echo_yellow 输出黄色文本 可加背景颜色参数(背景默认不设置)
function echo_yellow() {
    if [ "$1" == "-b" ]; then
        Bg=$(($2))
        Content=$3
    else
        Bg="8"
        Content=$1
    fi
    Color $yellow $Bg $Content
}

# echo_blue 输出蓝色文本 可加背景颜色参数(背景默认不设置)
function echo_blue() {
    if [ "$1" == "-b" ]; then
        Bg=$(($2))
        Content=$3
    else
        Bg="8"
        Content=$1
    fi
    Color $blue $Bg $Content
}

# echo_magenta 输出洋红色文本 可加背景颜色参数(背景默认不设置)
function echo_magenta() {
    if [ "$1" == "-b" ]; then
        Bg=$(($2))
        Content=$3
    else
        Bg="8"
        Content=$1
    fi
    Color $magenta $Bg $Content
}

# echo_cyan 输出青色文本 可加背景颜色参数(背景默认不设置)
function echo_cyan() {
    if [ "$1" == "-b" ]; then
        Bg=$(($2))
        Content=$3
    else
        Bg="8"
        Content=$1
    fi
    Color $cyan $Bg $Content
}

# echo_white 输出白色文本 可加背景颜色参数(背景默认不设置)
function echo_white() {
    if [ "$1" == "-b" ]; then
        Bg=$(($2))
        Content=$3
    else
        Bg="8"
        Content=$1
    fi
    Color $white $Bg $Content
}

#main 防止导入其他脚本中使用时，会输出以下内容
case $1 in
    show)
    echo -e "example ... [\e[1;30m black \e[0m|\e[1;31m red \e[0m|\e[1;32m green \e[0m|\e[1;33m yellow \e[0m|\e[1;34m blue \e[0m|\e[1;35m magenta \e[0m|\e[1;36m cyan \e[0m|\e[1;37m white \e[0m]"
    echo -en "using [\e[1;40m echo_black \"hello\"\e[0m ] to output black text: "
    echo_black "hello"
    echo -en "using [\e[1;41m echo_red \"hello\" \e[0m] to output red text: "
    echo_red "hello"
    echo -en "using [\e[1;42m echo_green \"hello\" \e[0m] to output green text: "
    echo_green "hello"
    echo -en "using [\e[1;43m echo_yellow \"hello\" \e[0m] to output yellow text: "
    echo_yellow "hello"
    echo -en "using [\e[1;44m echo_blue \"hello\" \e[0m] to output blue text: "
    echo_blue "hello"
    echo -en "using [\e[1;45m echo_magenta \"hello\" \e[0m] to output magenta text: "
    echo_magenta "hello"
    echo -en "using [\e[1;46m echo_cyan \"hello\" \e[0m] to output cyan text: "
    echo_cyan "hello"
    echo -en "using [\e[1;47m echo_white \"hello\" \e[0m] to output white text: "
    echo_white "hello"
    echo -en "using [\e[30;47m echo_black -b white \"hello,world!\" \e[0m] to output black text with white background: "
    echo_black -b white "hello, world!"
    ;;
    *)
    ;;
esac
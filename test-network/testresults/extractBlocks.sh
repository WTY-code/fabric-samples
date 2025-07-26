#!/bin/bash

# 参数检查
if [ $# -ne 3 ]; then
    echo "错误：需要3个参数，依次为 h0, step, num"
    echo "用法: $0 <起始值> <步长> <循环次数>"
    exit 1
fi

# 参数赋值
h0=$1
step=$2
num=$3

# 循环执行命令
for ((i=0; i<num; i++)); do
    value=$(( h0 + i * step ))  # 计算当前值
    echo "正在执行: peer channel fetch $value \"mychannel.block$value\" -c mychannel"
    # 实际执行时删除下一行的注释，并确保peer命令可用
    peer channel fetch $value "mychannel.block$value" -c mychannel
done

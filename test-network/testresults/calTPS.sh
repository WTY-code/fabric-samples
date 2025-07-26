#!/bin/bash

# 说明：本文件从区块链中读取指定的多个区块，计算区块中交易总数，以及第一个区块和最后一个区块的时间间隔，并计算TPS。

# 参数检查
if [ $# -ne 3 ]; then
    echo "错误：需要3个参数，依次为 h0, step, num"
    echo "用法: $0 <起始值> <步长> <循环次数>"
    exit 1
fi

export PATH=/root/ruc/fabric-samples/bin:$PATH

# 参数赋值
h0=$1
step=$2
num=$3

total=0 #区块中交易总数
# 循环执行命令
for ((i=0; i<num; i++)); do
    value=$(( h0 + i * step ))  # 计算当前值
    docker cp peer0.org1.example.com:/root/"mychannel.block$value" .   #从容器中读取区块
    configtxlator proto_decode  --type common.Block --input "mychannel.block$value" > "mychannel.block$value.json"  #提取为json文件
    count=$(grep -c 'tx_id' "mychannel.block$value.json" 2>/dev/null)    #统计区块中交易个数
    echo "高度为$value 的区块交易个数： $count"
    total=$((total + count))
done

# 定义两个文件路径
file1="mychannel.block$h0.json"
file2="mychannel.block$value.json"

# 从两个文件中提取时间戳行
timestamp1=$(grep 'timestamp' "$file1" | head -n 1)
timestamp2=$(grep 'timestamp' "$file2" | head -n 1)

# 步骤2：提取完整时间组件并转换为总秒数
parse_time() {
    local time_str=$(echo "$1" | cut -d'"' -f4 | cut -d'T' -f2)
    local hour=$(echo "$time_str" | cut -d: -f1)
    local minute=$(echo "$time_str" | cut -d: -f2)
    local second=$(echo "$time_str" | cut -d: -f3 | cut -d. -f1)
    echo $((10#$hour * 3600 + 10#$minute * 60 + 10#$second))
}

# 计算两个时间戳的总秒数
time1=$(parse_time "$timestamp1")
time2=$(parse_time "$timestamp2")

# 计算绝对时间差
difference=$((time2 - time1))

# 输出完整时间信息和差值
echo "$file1 时间戳分解：$(echo "$timestamp1" | cut -d'"' -f4)"
echo "$file2 时间戳分解：$(echo "$timestamp2" | cut -d'"' -f4)"
echo "-------------------------------------"
echo "时间差值（秒）: $difference"

tps=$(echo "scale=2; $total / $difference" | bc)  # 保留两位小数
tps=$(echo "$tps * $step" | bc)

echo "TPS为: $tps"





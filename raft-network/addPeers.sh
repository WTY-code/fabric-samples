#!/bin/bash

# 定义容器数组
containers=("peer0.org1.cli" "peer1.org1.cli" "peer0.org2.cli" "peer1.org2.cli")

# 遍历所有容器并执行加入通道操作
for container in "${containers[@]}"; do
    echo "正在操作容器: $container"
    docker exec "$container" peer channel join -b ./channel-artifacts/genesis.block
    
    # 检查上一条命令的退出状态
    if [ $? -eq 0 ]; then
        echo "$container 成功加入通道"
    else
        echo "错误：$container 加入通道失败" >&2
        exit 1
    fi
    echo ""
done

echo "所有节点已成功加入通道！"
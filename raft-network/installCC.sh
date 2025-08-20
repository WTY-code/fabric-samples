#!/bin/bash

# 安装链码自动化脚本
# 需要在宿主机执行，且确保所有Docker容器处于运行状态

# 1. 打包链码（在peer0.org1.cli容器中执行）
docker exec peer0.org1.cli bash -c '
    echo "在 peer0.org1.cli 容器中打包链码..."
    peer lifecycle chaincode package fabcar.tar.gz \
        --path /opt/gopath/src/github.com/hyperledger/raft-network/chaincode/go \
        --lang golang \
        --label fabcar_1.0
'

# 2. 将链码包从容器复制到宿主机
echo "将链码包复制到宿主机..."
docker cp peer0.org1.cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/fabcar.tar.gz .

# 3. 将链码包分发到其他节点
echo "分发链码包到所有节点..."
docker cp fabcar.tar.gz peer1.org1.cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/
docker cp fabcar.tar.gz peer0.org2.cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/
docker cp fabcar.tar.gz peer1.org2.cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/

# 4. 在所有节点安装链码
echo "在所有节点安装链码..."
nodes=("peer0.org1.cli" "peer1.org1.cli" "peer0.org2.cli" "peer1.org2.cli")

for node in "${nodes[@]}"; do
    echo "在 $node 安装链码..."
    docker exec $node peer lifecycle chaincode install fabcar.tar.gz
    if [ $? -eq 0 ]; then
        echo "$node 安装成功!"
    else
        echo "$node 安装失败!" >&2
        exit 1
    fi
done

# 清理临时文件
echo "清理临时文件..."
rm fabcar.tar.gz

echo "链码安装完成!"
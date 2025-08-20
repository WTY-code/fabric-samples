#!/bin/bash

# 机器配置
MACHINE1_IP=$1
MACHINE1_PASS=$2
MACHINE2_IP=$3
MACHINE2_PASS=$4
WORK_DIR="/root/ruc/fabric-samples/multiple-deployment"
LOCAL_TMP_DIR="/root/ruc/fabric-samples/multiple-deployment/tmp"

mkdir -p $LOCAL_TMP_DIR

# 执行远程命令函数
run_remote() {
  ip=$1
  pass=$2
  cmd=$3
  sshpass -p "$pass" ssh -o StrictHostKeyChecking=no root@$ip "cd $WORK_DIR && $cmd"
}

# 步骤0: 清理残留网络
echo "===== 清理网络 ====="
run_remote $MACHINE1_IP $MACHINE1_PASS "docker-compose -f docker-compose-up-server1.yaml down"
run_remote $MACHINE1_IP $MACHINE1_PASS "find channel-artifacts/ -type f ! -name 'genesis.block' -delete"
run_remote $MACHINE1_IP $MACHINE1_PASS "docker stop \$(docker ps -q) || true"
run_remote $MACHINE1_IP $MACHINE1_PASS "docker rm \$(docker ps -aq) || true"

run_remote $MACHINE2_IP $MACHINE2_PASS "docker-compose -f docker-compose-up-server2.yaml down"
run_remote $MACHINE2_IP $MACHINE2_PASS "find channel-artifacts/ -type f ! -name 'genesis.block' -delete"
run_remote $MACHINE2_IP $MACHINE2_PASS "docker stop \$(docker ps -q) || true"
run_remote $MACHINE2_IP $MACHINE2_PASS "docker rm \$(docker ps -aq) || true"
echo "===== 清理网络 done ====="

# 步骤1: 启动网络
echo "===== 启动网络 ====="
run_remote $MACHINE1_IP $MACHINE1_PASS "docker-compose -f docker-compose-up-server1.yaml up -d"
run_remote $MACHINE2_IP $MACHINE2_PASS "docker-compose -f docker-compose-up-server2.yaml up -d"
echo "===== 启动网络 done ====="
sleep 10  # 等待服务启动

# 步骤2: 加入Orderer
echo "===== 加入Orderer ====="
# run_remote $MACHINE1_IP $MACHINE1_PASS "./addOrderers.sh"
./addOrderers.sh
echo "===== 加入Orderer done ====="
sleep 3


# 步骤3: 加入Peer
echo "===== 加入Peer节点 ====="
for machine in 1 2; do
  for cli in cli1 cli2; do
    ip_var="MACHINE${machine}_IP"
    pass_var="MACHINE${machine}_PASS"
    run_remote ${!ip_var} ${!pass_var} "docker exec $cli peer channel join -b ./channel-artifacts/genesis.block"
  done
done
echo "===== 加入Peer节点 done ====="
sleep 5

echo "===== 检查各节点账本高度 ====="
# 检查各节点账本高度
for machine in 1 2; do
  ip_var="MACHINE${machine}_IP"
  pass_var="MACHINE${machine}_PASS"
    
  # 在所有容器上检查链码
  for cli in cli1 cli2; do
    echo "ledger height: $MACHINE${machine} $cli"
    run_remote ${!ip_var} ${!pass_var} "docker exec $cli peer channel getinfo -c mychannel"
    sleep 2
  done
done
echo "===== 检查各节点账本高度 done====="

# 步骤4: 设置锚节点
echo "===== 设置锚节点 ====="
run_remote $MACHINE1_IP $MACHINE1_PASS "docker cp setOrg1Anchor.sh cli1:/opt/gopath/src/github.com/hyperledger/fabric/peer"
run_remote $MACHINE1_IP $MACHINE1_PASS "docker exec cli1 chmod +x setOrg1Anchor.sh"
run_remote $MACHINE1_IP $MACHINE1_PASS "docker exec cli1 ./setOrg1Anchor.sh"
sleep 5

run_remote $MACHINE2_IP $MACHINE2_PASS "docker cp setOrg2Anchor.sh cli1:/opt/gopath/src/github.com/hyperledger/fabric/peer"
run_remote $MACHINE2_IP $MACHINE2_PASS "docker exec cli1 chmod +x setOrg2Anchor.sh"
run_remote $MACHINE2_IP $MACHINE2_PASS "docker exec cli1 ./setOrg2Anchor.sh"
sleep 5

echo "===== 检查各节点账本高度 ====="
# 检查各节点账本高度
for machine in 1 2; do
  ip_var="MACHINE${machine}_IP"
  pass_var="MACHINE${machine}_PASS"
    
  # 在所有容器上检查链码
  for cli in cli1 cli2; do
    echo "ledger height: $MACHINE${machine} $cli"
    run_remote ${!ip_var} ${!pass_var} "docker exec $cli peer channel getinfo -c mychannel"
    sleep 2
  done
done
echo "===== 检查各节点账本高度 done====="

# exit 0

# # 步骤5: 安装链码
# echo "===== 安装链码 ====="
# # 在机器1打包链码
# run_remote $MACHINE1_IP $MACHINE1_PASS "docker exec cli1 peer lifecycle chaincode package fabcar.tar.gz --path /opt/gopath/src/github.com/hyperledger/multiple-deployment/chaincode/go --lang golang --label fabcar_1.0"

# # 分发链码包
# run_remote $MACHINE1_IP $MACHINE1_PASS "docker cp cli1:/opt/gopath/src/github.com/hyperledger/fabric/peer/fabcar.tar.gz ."
# sshpass -p $MACHINE1_PASS scp root@$MACHINE1_IP:$WORK_DIR/fabcar.tar.gz .
# sshpass -p $MACHINE2_PASS scp fabcar.tar.gz root@$MACHINE2_IP:$WORK_DIR/
# rm fabcar.tar.gz

# # 所有节点安装链码
# for machine in 1 2; do
#   ip_var="MACHINE${machine}_IP"
#   pass_var="MACHINE${machine}_PASS"
#   for cli in cli1 cli2; do
#     run_remote ${!ip_var} ${!pass_var} "docker cp fabcar.tar.gz $cli:/opt/gopath/src/github.com/hyperledger/fabric/peer"
#     run_remote ${!ip_var} ${!pass_var} "docker exec $cli peer lifecycle chaincode install fabcar.tar.gz"
#     sleep 10
#   done
# done

# # 步骤5: 修复安装链码
# echo "===== 安装链码 ====="
# # 在机器1打包链码
# run_remote $MACHINE1_IP $MACHINE1_PASS "docker exec cli1 peer lifecycle chaincode package /opt/gopath/src/github.com/hyperledger/fabric/peer/fabcar.tar.gz --path /opt/gopath/src/github.com/hyperledger/multiple-deployment/chaincode/go --lang golang --label fabcar_1.0"

# # 获取链码包ID（在机器1）
# PACKAGE_ID=$(sshpass -p $MACHINE1_PASS ssh root@$MACHINE1_IP "docker exec cli1 peer lifecycle chaincode calculatepackageid fabcar.tar.gz" | tr -d '\r')

# # 分发链码包到所有节点
# for machine in 1 2; do
#   for cli in cli1 cli2; do
#     ip_var="MACHINE${machine}_IP"
#     pass_var="MACHINE${machine}_PASS"
    
#     # 只在非打包节点或需要安装的节点上执行
#     if [[ "$machine" != "1" ]] || [[ "$cli" != "cli1" ]]; then
#       run_remote ${!ip_var} ${!pass_var} "docker exec cli1 peer lifecycle chaincode package /opt/gopath/src/github.com/hyperledger/fabric/peer/fabcar.tar.gz --path /opt/gopath/src/github.com/hyperledger/multiple-deployment/chaincode/go --lang golang --label fabcar_1.0"
#     fi
    
#     # 安装链码
#     run_remote ${!ip_var} ${!pass_var} "docker exec $cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/fabcar.tar.gz"
#   done
# done
# echo "===== 安装链码 done ====="

# # 步骤5: 修复链码安装
# echo "===== 安装链码 ====="
# # 在机器1的cli1容器中打包链码
# run_remote $MACHINE1_IP $MACHINE1_PASS "docker exec cli1 peer lifecycle chaincode package /opt/gopath/src/github.com/hyperledger/fabric/peer/fabcar.tar.gz --path /opt/gopath/src/github.com/hyperledger/multiple-deployment/chaincode/go --lang golang --label fabcar_1.0"

# # 获取链码包ID（在机器1）
# PACKAGE_ID=$(sshpass -p $MACHINE1_PASS ssh root@$MACHINE1_IP "docker exec cli1 peer lifecycle chaincode calculatepackageid fabcar.tar.gz" | tr -d '\r')

# echo "链码包ID: $PACKAGE_ID"

# # 在所有节点安装链码
# for machine in 1 2; do
#   for cli in cli1 cli2; do
#     ip_var="MACHINE${machine}_IP"
#     pass_var="MACHINE${machine}_PASS"
    
#     # 对于非打包节点，需要先将链码包复制到容器
#     if [[ "$machine" == "2" ]]; then
#       # 从机器1获取链码包
#       sshpass -p $MACHINE1_PASS scp root@$MACHINE1_IP:$WORK_DIR/fabcar.tar.gz .
#       sshpass -p $MACHINE2_PASS scp fabcar.tar.gz root@$MACHINE2_IP:$WORK_DIR/
#       rm fabcar.tar.gz
      
#       # 将链码包复制到容器
#       run_remote ${!ip_var} ${!pass_var} "docker cp fabcar.tar.gz $cli:/opt/gopath/src/github.com/hyperledger/fabric/peer"
#     fi
    
#     # 安装链码
#     run_remote ${!ip_var} ${!pass_var} "docker exec $cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/fabcar.tar.gz"
#   done
# done

# 步骤5: 修复链码安装
echo "===== 安装链码 ====="
# 在机器1的cli1容器中打包链码
run_remote $MACHINE1_IP $MACHINE1_PASS "docker exec cli1 peer lifecycle chaincode package /opt/gopath/src/github.com/hyperledger/fabric/peer/fabcar.tar.gz --path /opt/gopath/src/github.com/hyperledger/multiple-deployment/chaincode/go --lang golang --label fabcar_1.0"

# 将链码包从机器1的容器复制到宿主机
run_remote $MACHINE1_IP $MACHINE1_PASS "docker cp cli1:/opt/gopath/src/github.com/hyperledger/fabric/peer/fabcar.tar.gz $WORK_DIR"

# 将链码包从机器1复制到本地
sshpass -p $MACHINE1_PASS scp root@$MACHINE1_IP:$WORK_DIR/fabcar.tar.gz $LOCAL_TMP_DIR
# echo "看multiple-deployment和multiple-deployment/tmp是否有链码包"

# 获取链码包ID（在机器1）
# PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid $LOCAL_TMP_DIR/fabcar.tar.gz | tr -d '\r')
PACKAGE_ID=$(sshpass -p $MACHINE1_PASS ssh root@$MACHINE1_IP "docker exec cli1 peer lifecycle chaincode calculatepackageid fabcar.tar.gz" | tr -d '\r')
echo "链码包ID: $PACKAGE_ID"

# 分发链码包到所有机器
for machine in 1 2; do
  ip_var="MACHINE${machine}_IP"
  pass_var="MACHINE${machine}_PASS"
  
  # 跳过机器1（已经有链码包）
  if [ "$machine" != "1" ]; then
    sshpass -p ${!pass_var} scp $LOCAL_TMP_DIR/fabcar.tar.gz root@${!ip_var}:$WORK_DIR/
  fi
  
  # 在所有容器上安装链码
  for cli in cli1 cli2; do
    run_remote ${!ip_var} ${!pass_var} "docker cp $WORK_DIR/fabcar.tar.gz $cli:/opt/gopath/src/github.com/hyperledger/fabric/peer"
    run_remote ${!ip_var} ${!pass_var} "docker exec $cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/fabcar.tar.gz"
  done
done

# 清理本地临时文件
rm $LOCAL_TMP_DIR/fabcar.tar.gz
rmdir $LOCAL_TMP_DIR

sleep 5

# 检查各个peer节点链码安装情况
for machine in 1 2; do
  ip_var="MACHINE${machine}_IP"
  pass_var="MACHINE${machine}_PASS"
    
  # 在所有容器上检查链码
  for cli in cli1 cli2; do
    run_remote ${!ip_var} ${!pass_var} "docker exec $cli peer lifecycle chaincode queryinstalled --output json"
  done
done

# exit 0

# # 步骤6: 部署链码（序列1）
# echo "===== 部署链码序列1 ====="
# run_remote $MACHINE1_IP $MACHINE1_PASS "docker exec cli1 peer lifecycle chaincode approveformyorg -o orderer0.example.com:7050 \
#   --ordererTLSHostnameOverride orderer0.example.com --tls \
#   --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
#   --channelID mychannel --name fabcar --version 1.0 \
#   --package-id $PACKAGE_ID --sequence 1"
# sleep 3

# run_remote $MACHINE2_IP $MACHINE2_PASS "docker exec cli1 peer lifecycle chaincode approveformyorg -o orderer0.example.com:7050 \
#   --ordererTLSHostnameOverride orderer0.example.com --tls \
#   --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
#   --channelID mychannel --name fabcar --version 1.0 \
#   --package-id $PACKAGE_ID --sequence 1"
# sleep 3

# # 提交链码（序列1）
# run_remote $MACHINE1_IP $MACHINE1_PASS "docker exec cli1 peer lifecycle chaincode commit \
#   -o orderer0.example.com:7050 --tls \
#   --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
#   --channelID mychannel --name fabcar --version 1.0 --sequence 1 \
#   --peerAddresses peer0.org1.example.com:7051 \
#   --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
#   --peerAddresses peer0.org2.example.com:7051 \
#   --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
# sleep 3

# # 步骤6: 部署链码（序列2）
# echo "===== 部署链码序列2 ====="
# run_remote $MACHINE1_IP $MACHINE1_PASS "docker exec cli1 peer lifecycle chaincode approveformyorg -o orderer0.example.com:7050 \
#   --ordererTLSHostnameOverride orderer0.example.com --tls \
#   --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
#   --channelID mychannel --name fabcar --version 1.0 \
#   --package-id $PACKAGE_ID --sequence 2"
# sleep 3

# run_remote $MACHINE2_IP $MACHINE2_PASS "docker exec cli1 peer lifecycle chaincode approveformyorg -o orderer0.example.com:7050 \
#   --ordererTLSHostnameOverride orderer0.example.com --tls \
#   --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
#   --channelID mychannel --name fabcar --version 1.0 \
#   --package-id $PACKAGE_ID --sequence 2"
# sleep 3

# # 提交链码（序列2）
# run_remote $MACHINE2_IP $MACHINE2_PASS "docker exec cli1 peer lifecycle chaincode commit \
#   -o orderer0.example.com:7050 --tls \
#   --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
#   --channelID mychannel --name fabcar --version 1.0 --sequence 2 \
#   --peerAddresses peer0.org1.example.com:7051 \
#   --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
#   --peerAddresses peer0.org2.example.com:7051 \
#   --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"



# 步骤6: 部署链码（序列1）
echo "===== 部署链码序列1 ====="
run_remote $MACHINE1_IP $MACHINE1_PASS "docker exec cli1 peer lifecycle chaincode approveformyorg -o orderer0.example.com:7050 \
  --ordererTLSHostnameOverride orderer0.example.com --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
  --channelID mychannel --name fabcar --version 1.0 \
  --package-id $PACKAGE_ID --sequence 1"

run_remote $MACHINE2_IP $MACHINE2_PASS "docker exec cli1 peer lifecycle chaincode approveformyorg -o orderer0.example.com:7050 \
  --ordererTLSHostnameOverride orderer0.example.com --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
  --channelID mychannel --name fabcar --version 1.0 \
  --package-id $PACKAGE_ID --sequence 1"

# 检查所有组织是否已批准
echo "===== 检查链码序列1是否已获得足够批准 ====="
MAX_CHECKS=10
CHECK_INTERVAL=5
ALL_APPROVED=0

for i in $(seq 1 $MAX_CHECKS); do
  echo "检查批准状态 (尝试 $i/$MAX_CHECKS) ..."
  
  # 在机器1上检查批准状态（使用jq解析）
  APPROVAL_JSON=$(run_remote $MACHINE1_IP $MACHINE1_PASS "docker exec cli1 peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name fabcar --version 1.0 --sequence 1 --output json")
  
  ORG1_APPROVED=$(echo $APPROVAL_JSON | jq -r '.approvals.Org1MSP')
  ORG2_APPROVED=$(echo $APPROVAL_JSON | jq -r '.approvals.Org2MSP')
  
  echo "组织批准状态: Org1MSP=$ORG1_APPROVED, Org2MSP=$ORG2_APPROVED"
  
  if [ "$ORG1_APPROVED" = "true" ] && [ "$ORG2_APPROVED" = "true" ]; then
    echo "所有组织已批准链码定义"
    ALL_APPROVED=1
    break
  else
    if [ $i -eq $MAX_CHECKS ]; then
      echo "错误: 链码定义未获得足够批准"
      exit 1
    fi
    sleep $CHECK_INTERVAL
  fi
done

if [ $ALL_APPROVED -eq 1 ]; then
  # 提交链码（序列1）
  echo "===== 提交链码序列1 ====="
  run_remote $MACHINE1_IP $MACHINE1_PASS "docker exec cli1 peer lifecycle chaincode commit \
    -o orderer0.example.com:7050 --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
    --channelID mychannel --name fabcar --version 1.0 --sequence 1 \
    --peerAddresses peer0.org1.example.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses peer0.org2.example.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
else
  echo "错误: 未能获得所有组织批准"
  exit 1
fi

# 步骤6: 部署链码（序列2）
echo "===== 部署链码序列2 ====="
run_remote $MACHINE1_IP $MACHINE1_PASS "docker exec cli1 peer lifecycle chaincode approveformyorg -o orderer0.example.com:7050 \
  --ordererTLSHostnameOverride orderer0.example.com --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
  --channelID mychannel --name fabcar --version 1.0 \
  --package-id $PACKAGE_ID --sequence 2"

run_remote $MACHINE2_IP $MACHINE2_PASS "docker exec cli1 peer lifecycle chaincode approveformyorg -o orderer0.example.com:7050 \
  --ordererTLSHostnameOverride orderer0.example.com --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
  --channelID mychannel --name fabcar --version 1.0 \
  --package-id $PACKAGE_ID --sequence 2"

# 检查所有组织是否已批准
echo "===== 检查链码序列2是否已获得足够批准 ====="
ALL_APPROVED=0

for i in $(seq 1 $MAX_CHECKS); do
  echo "检查批准状态 (尝试 $i/$MAX_CHECKS) ..."
  
  # 在机器1上检查批准状态（使用jq解析）
  APPROVAL_JSON=$(run_remote $MACHINE1_IP $MACHINE1_PASS "docker exec cli1 peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name fabcar --version 1.0 --sequence 2 --output json")
  
  ORG1_APPROVED=$(echo $APPROVAL_JSON | jq -r '.approvals.Org1MSP')
  ORG2_APPROVED=$(echo $APPROVAL_JSON | jq -r '.approvals.Org2MSP')
  
  echo "组织批准状态: Org1MSP=$ORG1_APPROVED, Org2MSP=$ORG2_APPROVED"
  
  if [ "$ORG1_APPROVED" = "true" ] && [ "$ORG2_APPROVED" = "true" ]; then
    echo "所有组织已批准链码定义"
    ALL_APPROVED=1
    break
  else
    if [ $i -eq $MAX_CHECKS ]; then
      echo "错误: 链码定义未获得足够批准"
      exit 1
    fi
    sleep $CHECK_INTERVAL
  fi
done

if [ $ALL_APPROVED -eq 1 ]; then
  # 提交链码（序列2）
  echo "===== 提交链码序列2 ====="
  run_remote $MACHINE2_IP $MACHINE2_PASS "docker exec cli1 peer lifecycle chaincode commit \
    -o orderer0.example.com:7050 --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
    --channelID mychannel --name fabcar --version 1.0 --sequence 2 \
    --peerAddresses peer0.org1.example.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses peer0.org2.example.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
else
  echo "错误: 未能获得所有组织批准"
  exit 1
fi

# 验证链码已提交（可选）
echo "===== 验证链码提交 ====="
run_remote $MACHINE1_IP $MACHINE1_PASS "docker exec cli1 peer lifecycle chaincode querycommitted --channelID mychannel --name fabcar"
run_remote $MACHINE2_IP $MACHINE2_PASS "docker exec cli1 peer lifecycle chaincode querycommitted --channelID mychannel --name fabcar"

echo "===== 部署完成 ====="
#!/bin/bash

# 部署链码自动化脚本
# 需要在宿主机执行，且确保所有Docker容器处于运行状态

# 1. 获取链码包ID（在peer0.org1.cli容器中）
echo "计算链码包ID..."
PACKAGE_ID=$(docker exec peer0.org1.cli peer lifecycle chaincode calculatepackageid fabcar.tar.gz)
echo "链码包ID: $PACKAGE_ID"

# 2. 各组织批准链码定义
echo "组织1批准链码定义..."
docker exec peer0.org1.cli bash -c "
    peer lifecycle chaincode approveformyorg -o orderer0.example.com:7050 \
    --ordererTLSHostnameOverride orderer0.example.com \
    --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
    --channelID mychannel \
    --name fabcar \
    --version 1.0 \
    --package-id $PACKAGE_ID \
    --sequence 1
"

echo "组织2批准链码定义..."
docker exec peer0.org2.cli bash -c "
    peer lifecycle chaincode approveformyorg -o orderer0.example.com:7050 \
    --ordererTLSHostnameOverride orderer0.example.com \
    --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
    --channelID mychannel \
    --name fabcar \
    --version 1.0 \
    --package-id $PACKAGE_ID \
    --sequence 1
"

sleep 3
# 3. 检查批准状态
echo "检查链码批准状态..."
docker exec peer0.org1.cli peer lifecycle chaincode checkcommitreadiness \
    --channelID mychannel \
    --name fabcar \
    --version 1.0 \
    --sequence 1 \
    --output json

read -p "检查所有组织是否已批准? (y/n): " proceed
if [ "$proceed" != "y" ]; then
    echo "批准未完成，停止部署"
    exit 1
fi

# 4. 提交链码定义
echo "提交链码定义..."
# docker exec peer0.org1.cli bash -c "
#     peer lifecycle chaincode commit \
#     -o orderer0.example.com:7050 \
#     --tls \
#     --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
#     --channelID mychannel \
#     --name fabcar \
#     --version 1.0 \
#     --sequence 1 \
#     --peerAddresses peer0.org1.example.com:7051 \
#     --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
#     --peerAddresses peer0.org2.example.com:8051 \
#     --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
# "

docker exec peer0.org1.cli bash -c "peer lifecycle chaincode commit \
  -o orderer0.example.com:7050 \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem \
  --channelID mychannel \
  --name fabcar \
  --version 1.0 \
  --sequence 1 \
  --peerAddresses peer0.org1.example.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
  --peerAddresses peer0.org2.example.com:8051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
  --peerAddresses peer1.org1.example.com:7151 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt \
  --peerAddresses peer1.org2.example.com:8151 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt"

sleep 3
# 5. 验证链码部署
echo "验证链码部署状态..."
docker exec peer0.org1.cli peer lifecycle chaincode querycommitted \
    --channelID mychannel \
    --name fabcar

echo "链码部署完成!"
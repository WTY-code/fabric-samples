#!/bin/bash

# 设置锚节点（org1）
docker cp setOrg1Anchor.sh peer0.org1.cli:/opt/gopath/src/github.com/hyperledger/fabric/peer
docker exec peer0.org1.cli chmod +x setOrg1Anchor.sh
# docker exec peer0.org1.cli ./setOrg1Anchor.sh
docker exec -it peer0.org1.cli /bin/bash -c "./setOrg1Anchor.sh"

# 设置锚节点（org2）
docker cp setOrg2Anchor.sh peer0.org2.cli:/opt/gopath/src/github.com/hyperledger/fabric/peer
docker exec peer0.org2.cli chmod +x setOrg2Anchor.sh
# docker exec peer0.org2.cli ./setOrg2Anchor.sh
docker exec -it peer0.org2.cli /bin/bash -c "./setOrg2Anchor.sh"

echo "锚节点设置完成"
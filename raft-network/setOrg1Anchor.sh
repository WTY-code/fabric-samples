set -x
peer channel fetch config ./channel-artifacts/config_block.pb -o orderer0.example.com:7050 --ordererTLSHostnameOverride orderer0.example.com -c mychannel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem

set -x
configtxlator proto_decode --input ./channel-artifacts/config_block.pb --type common.Block --output ./channel-artifacts/config_block.json

set -x
jq '.data.data[0].payload.data.config' ./channel-artifacts/config_block.json > ./channel-artifacts/Org1MSPconfig.json

set -x
jq '.channel_group.groups.Application.groups.Org1MSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.org1.example.com","port": 7051}]},"version": "0"}}' ./channel-artifacts/Org1MSPconfig.json > ./channel-artifacts/Org1MSPmodified_config.json

set -x
configtxlator proto_encode --input ./channel-artifacts/Org1MSPconfig.json --type common.Config --output ./channel-artifacts/original_config.pb

set -x
configtxlator proto_encode --input ./channel-artifacts/Org1MSPmodified_config.json --type common.Config --output ./channel-artifacts/modified_config.pb

set -x
configtxlator compute_update --channel_id mychannel --original ./channel-artifacts/original_config.pb --updated ./channel-artifacts/modified_config.pb --output ./channel-artifacts/config_update.pb

set -x
configtxlator proto_decode --input ./channel-artifacts/config_update.pb --type common.ConfigUpdate --output ./channel-artifacts/config_update.json

set -x
echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat ./channel-artifacts/config_update.json)'}}}' | jq . > ./channel-artifacts/config_update_in_envelope.json

set -x
configtxlator proto_encode --input ./channel-artifacts/config_update_in_envelope.json --type common.Envelope --output ./channel-artifacts/Org1MSPanchors.tx

set -x
peer channel update -o orderer0.example.com:7050 --ordererTLSHostnameOverride orderer0.example.com -c mychannel -f ./channel-artifacts/Org1MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
#!/bin/bash

echo "=== Fixed Fabric Network Diagnosis ==="

# IMPORTANT: Set up the same environment as network_add.sh
ROOTDIR=$(cd "$(dirname "$0")" && pwd)
export PATH=${ROOTDIR}/../bin:${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/bft-configtx
export VERBOSE=false

# Alternative paths for fabric binaries
FABRIC_PATHS=(
    "${ROOTDIR}/../bin"
    "/root/ruc/fabric-samples/bin"
    "../bin"
    "./bin"
)

echo "1. Setting up Fabric environment..."
for fabric_path in "${FABRIC_PATHS[@]}"; do
    if [ -f "${fabric_path}/peer" ]; then
        export PATH="${fabric_path}:${PATH}"
        echo "✅ Found Fabric binaries in: ${fabric_path}"
        break
    fi
done

# Test if peer command is available
if command -v peer >/dev/null 2>&1; then
    echo "✅ peer command is available"
    echo "Peer version: $(peer version | head -1)"
else
    echo "❌ peer command not found, trying to locate..."
    find /root -name "peer" -type f 2>/dev/null | head -5
    exit 1
fi

# Source the environment variables (same as network_add.sh)
echo -e "\n2. Loading environment variables..."
if [ -f "scripts/envVar.sh" ]; then
    . scripts/envVar.sh
    echo "✅ Environment variables loaded"
else
    echo "❌ scripts/envVar.sh not found"
    exit 1
fi

echo -e "\n3. Checking channel membership for each organization..."
for org in 1 2 3; do
    echo -e "\n--- Organization $org ---"
    setGlobals_MultiPeer $org
    
    echo "Current peer address: $CORE_PEER_ADDRESS"
    echo "Current MSP ID: $CORE_PEER_LOCALMSPID"
    
    # Check channel membership
    echo "Channels this peer has joined:"
    peer channel list 2>/dev/null || echo "Failed to get channel list"
    
    # Check for specific channel
    CHANNELS=$(peer channel list 2>/dev/null | grep -v "Channels peers has joined:" | sed '/^$/d' | xargs)
    if [[ "$CHANNELS" == *"mychannel"* ]]; then
        echo "✅ Found mychannel"
    else
        echo "❌ mychannel not found. Available channels: $CHANNELS"
    fi
done

echo -e "\n4. Checking chaincode deployment..."
for org in 1 2 3; do
    echo -e "\n--- Checking chaincode on org$org ---"
    setGlobals_MultiPeer $org
    
    # Check committed chaincodes on mychannel
    echo "Committed chaincodes on mychannel:"
    committed_output=$(peer lifecycle chaincode querycommitted --channelID mychannel 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "$committed_output"
        if [[ "$committed_output" == *"fabcar"* ]]; then
            echo "✅ fabcar chaincode found on org$org"
        else
            echo "⚠️  fabcar chaincode not found on org$org, but other chaincodes exist"
        fi
    else
        echo "❌ Failed to query committed chaincodes on org$org"
    fi
done

echo -e "\n5. Testing chaincode functionality..."
setGlobals_MultiPeer 1
echo "Testing fabcar chaincode query..."
query_result=$(peer chaincode query -C mychannel -n fabcar -c '{"function":"QueryAllCars","Args":[]}' 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ Chaincode query successful"
    echo "Result: $query_result"
else
    echo "❌ Chaincode query failed"
    echo "Trying to invoke InitLedger first..."
    
    # Try to initialize the ledger
    peer chaincode invoke \
      -o localhost:7050 \
      --ordererTLSHostnameOverride orderer.example.com \
      --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
      -C mychannel \
      -n fabcar \
      --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
      --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
      --peerAddresses localhost:11051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt \
      -c '{"function":"InitLedger","Args":[]}' 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ InitLedger invocation successful"
        sleep 3
        # Try query again
        query_result=$(peer chaincode query -C mychannel -n fabcar -c '{"function":"QueryAllCars","Args":[]}' 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "✅ Chaincode query successful after initialization"
            echo "Result: $query_result"
        fi
    else
        echo "❌ InitLedger invocation failed"
    fi
fi

echo -e "\n6. Network connectivity test..."
setGlobals_MultiPeer 1
echo "Testing orderer connectivity..."
peer channel fetch config /tmp/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -c mychannel >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Orderer connectivity successful"
    rm -f /tmp/config_block.pb
else
    echo "❌ Orderer connectivity failed"
fi

echo -e "\n=== Diagnosis Complete ==="
echo "If chaincode is working above, your network is ready for Caliper!"
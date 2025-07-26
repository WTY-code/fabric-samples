#!/bin/bash

echo "=== Direct Chaincode Test ==="

export FABRIC_CFG_PATH=${PWD}/../config/
. scripts/envVar.sh

# Test 1: Try to invoke chaincode to create a car
echo -e "\n1. Testing CreateCar function..."
setGlobals 1

peer chaincode invoke \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C mychannel \
  -n fabcar \
  --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
  --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
  --peerAddresses localhost:11051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt \
  -c '{"function":"CreateCar","Args":["TEST001","Toyota","Camry","Blue","TestUser"]}'

echo -e "\nWaiting for transaction to be committed..."
sleep 3

# Test 2: Query all cars
echo -e "\n2. Testing QueryAllCars function..."
setGlobals 1
peer chaincode query \
  -C mychannel \
  -n fabcar \
  -c '{"function":"QueryAllCars","Args":[]}'

# Test 3: Query specific car
echo -e "\n3. Testing QueryCar function..."
setGlobals 1
peer chaincode query \
  -C mychannel \
  -n fabcar \
  -c '{"function":"QueryCar","Args":["TEST001"]}'

echo -e "\n=== Test Complete ==="
echo "If the above tests succeed, your chaincode is working correctly."
echo "The issue is likely in Caliper's network configuration."
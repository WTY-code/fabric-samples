#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

# imports
# test network home var targets to test-network folder
# the reason we use a var here is to accommodate scenarios
# where execution occurs from folders outside of default as $PWD, such as the test-network/addOrg3 folder.
# For setting environment variables, simple relative paths like ".." could lead to unintended references
# due to how they interact with FABRIC_CFG_PATH. It's advised to specify paths more explicitly,
# such as using "../${PWD}", to ensure that Fabric's environment variables are pointing to the correct paths.
TEST_NETWORK_HOME=${TEST_NETWORK_HOME:-${PWD}}
. ${TEST_NETWORK_HOME}/scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
export PEER0_ORG1_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
export PEER1_ORG1_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
export PEER2_ORG1_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
export PEER0_ORG2_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem
export PEER1_ORG2_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem
export PEER2_ORG2_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem
export PEER0_ORG3_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/tlsca/tlsca.org3.example.com-cert.pem
export PEER1_ORG3_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/tlsca/tlsca.org3.example.com-cert.pem
export PEER2_ORG3_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/tlsca/tlsca.org3.example.com-cert.pem

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  infoln "Using organization ${USING_ORG}"
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_LOCALMSPID=Org1MSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID=Org2MSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_LOCALMSPID=Org3MSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" = "true" ]; then
    env | grep CORE
  fi
}

# Set environment variables for the peer org
# Usage: setGlobals <ORG> [PEER_NUM]
# If PEER_NUM is not specified, defaults to peer0
setGlobals_MultiPeer() {
  local USING_ORG=""
  local PEER_NUM=0
  
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  
  # Second parameter is peer number (0, 1, or 2)
  if [ $# -ge 2 ]; then
    PEER_NUM=$2
  fi
  
  infoln "Using organization ${USING_ORG}, peer${PEER_NUM}"
  
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_LOCALMSPID=Org1MSP
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    
    if [ $PEER_NUM -eq 0 ]; then
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
      export CORE_PEER_ADDRESS=localhost:7051
    elif [ $PEER_NUM -eq 1 ]; then
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_ORG1_CA
      export CORE_PEER_ADDRESS=localhost:7061
    elif [ $PEER_NUM -eq 2 ]; then
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER2_ORG1_CA
      export CORE_PEER_ADDRESS=localhost:7071
    fi
    
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID=Org2MSP
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    
    if [ $PEER_NUM -eq 0 ]; then
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
      export CORE_PEER_ADDRESS=localhost:9051
    elif [ $PEER_NUM -eq 1 ]; then
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_ORG2_CA
      export CORE_PEER_ADDRESS=localhost:9061
    elif [ $PEER_NUM -eq 2 ]; then
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER2_ORG2_CA
      export CORE_PEER_ADDRESS=localhost:9071
    fi
    
  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_LOCALMSPID=Org3MSP
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
    
    if [ $PEER_NUM -eq 0 ]; then
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
      export CORE_PEER_ADDRESS=localhost:11051
    elif [ $PEER_NUM -eq 1 ]; then
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER1_ORG3_CA
      export CORE_PEER_ADDRESS=localhost:11061
    elif [ $PEER_NUM -eq 2 ]; then
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER2_ORG3_CA
      export CORE_PEER_ADDRESS=localhost:11071
    fi
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" = "true" ]; then
    env | grep CORE
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.org$1"
    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
	PEERS="$PEER"
    else
	PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    CA=PEER0_ORG$1_CA
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift
  done
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation. Can handle multiple peers per organization
parsePeerConnectionParameters_MultiPeer() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    local ORG=$1
    local PEER_NUM=0
    
    # Check if second argument is a peer number
    if [ $# -ge 2 ] && [[ "$2" =~ ^[0-2]$ ]]; then
      PEER_NUM=$2
      shift
    fi
    
    setGlobals_MultiPeer $ORG $PEER_NUM
    PEER="peer${PEER_NUM}.org${ORG}"
    
    ## Set peer addresses
    if [ -z "$PEERS" ]; then
      PEERS="$PEER"
    else
      PEERS="$PEERS $PEER"
    fi
    
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    
    ## Set path to TLS certificate
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --tlsRootCertFiles "${CORE_PEER_TLS_ROOTCERT_FILE}")
    
    # shift by one to get to the next organization
    shift
  done
}

# Enhanced version of parsePeerConnectionParameters to support multiple peers per org
# Usage: parsePeerConnectionParameters_Enhanced ORG1 PEER_COUNT1 ORG2 PEER_COUNT2 ...
# Example: parsePeerConnectionParameters_Enhanced 1 3 2 2 3 1
parsePeerConnectionParameters_Enhanced() {
  PEER_CONN_PARMS=()
  PEERS=""
  
  while [ "$#" -gt 1 ]; do
    local ORG=$1
    local PEER_COUNT=$2
    shift 2
    
    for ((peer=0; peer<$PEER_COUNT; peer++)); do
      setGlobals_MultiPeer $ORG $peer
      PEER="peer${peer}.org${ORG}"
      
      ## Set peer addresses
      if [ -z "$PEERS" ]; then
        PEERS="$PEER"
      else
        PEERS="$PEERS $PEER"
      fi
      
      PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
      PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --tlsRootCertFiles "${CORE_PEER_TLS_ROOTCERT_FILE}")
    done
  done
}

# Alternative: Include all peers for maximum redundancy
parsePeerConnectionParameters_AllPeers() {
  PEER_CONN_PARMS=()
  PEERS=""
  
  for ORG in 1 2 3; do
    for PEER_NUM in 0 1 2; do
      setGlobals_MultiPeer $ORG $PEER_NUM
      PEER="peer${PEER_NUM}.org${ORG}"
      
      ## Set peer addresses
      if [ -z "$PEERS" ]; then
        PEERS="$PEER"
      else
        PEERS="$PEERS $PEER"
      fi
      
      PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
      PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --tlsRootCertFiles "${CORE_PEER_TLS_ROOTCERT_FILE}")
    done
  done
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}

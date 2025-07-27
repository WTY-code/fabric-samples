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
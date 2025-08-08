#!/bin/bash

# 描述: NPU环境变量配置工具

# 检查IP地址格式
check_ip() {
    local ip=$1
    if [[ ! $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 1
    fi
    # 验证每个数字在0-255之间
    local IFS='.'
    local -a parts=($ip)
    for part in "${parts[@]}"; do
        if [[ $part -lt 0 || $part -gt 255 ]]; then
            return 1
        fi
    done
    return 0
}

# 检查是否提供了必要的参数
if [ "$#" -ne 3 ]; then
    echo "用法: $0 <master_ip> <container_ip> <world_size>"
    echo "示例: $0 10.0.0.26 10.0.0.26 32"
    echo "说明:"
    echo "  master_ip: 主节点IP地址"
    echo "  container_ip: 当前宿主机IP地址"
    echo "  world_size: 总的设备数量"
    exit 1
fi

CONTAINER_IP=$1

if ! check_ip "$CONTAINER_IP"; then
    echo "错误: 无效的容器IP地址格式: $CONTAINER_IP"
    exit 1
fi

# 准备要添加的环境变量配置
CONFIG="
# NPU环境配置
# source /usr/local/Ascend/mindie/set_env.sh
# source /usr/local/Ascend/ascend-toolkit/set_env.sh
# source /usr/local/Ascend/nnal/atb/set_env.sh
# source /usr/local/Ascend/atb-models/set_env.sh

# 设备和基础配置
export MIES_CONTAINER_IP=$CONTAINER_IP
export OMP_NUM_THREADS=10
export TASK_QUEUE_ENABLE=2
# CPU细粒度绑核
export CPU_AFFINITY_CONF=2

# 日志配置
export ASCEND_SLOG_PRINT_TO_STDOUT=0
export MINDIE_LLM_LOG_TO_STDOUT=0
export MINDIE_LOG_TO_STDOUT=0
export ATB_LOG_TO_STDOUT=0
export ATB_LOG_TO_FILE=1
export ASDOPS_LOG_TO_STDOUT=0
export ASDOPS_LOG_TO_FILE=1
# export MINDIE_LOG_LEVEL=ERROR  #加上这些会影响性能
# export ASCEND_GLOBAL_LOG_LEVEL=3
# export ASDOPS_LOG_LEVEL=ERROR
# export ATB_LOG_LEVEL=ERROR

# 性能优化配置
export NPU_MEMORY_FRACTION=0.95
export PYTORCH_NPU_ALLOC_CONF=expandable_segments:True
export ATB_WORKSPACE_MEM_ALLOC_ALG_TYPE=3
export ATB_WORKSPACE_MEM_ALLOC_GLOBAL=1

## 别名配置
alias cdm='cd /usr/local/Ascend/mindie/latest/mindie-service'
alias cdm-start='cd /usr/local/Ascend/mindie/latest/mindie-service/bin/mindieservice_daemon'
"

# 检查是否已经存在这些配置
if grep -q "NPU环境配置" ~/.bashrc; then
    echo "警告: 发现已存在的NPU环境配置，是否要更新？[y/N]"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        # 删除旧的配置（从"# NPU环境配置"开始到下一个空行）
        sed -i '/# NPU环境配置/,/^$/d' ~/.bashrc
        echo "已删除旧的配置"
    else
        echo "操作已取消"
        exit 0
    fi
fi

# 添加新的配置到~/.bashrc
echo "$CONFIG" >> ~/.bashrc

echo "配置已成功添加到 ~/.bashrc"
echo "配置信息:"
echo "  MIES_CONTAINER_IP（当前宿主机ip）: $CONTAINER_IP"
echo "请运行 'source ~/.bashrc' 使配置生效（全自动化配置请忽略）"

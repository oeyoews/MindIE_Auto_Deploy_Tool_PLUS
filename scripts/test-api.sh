#!/bin/bash

#########################
###   测试模型服务接口  ####
#########################

# base URL
BASE_URL="http://192.168.1.100:1025"

# 默认配置
DEFAULT_URL="$BASE_URL/v1/chat/completions"
DEFAULT_MODELS_URL="$BASE_URL/v1/models"
DEFAULT_TEMP=0.3
DEFAULT_STREAM=false
DEFAULT_MESSAGE="写一个 Python 程序，计算 1 到 100 的和"

# 获取模型 ID，并检查是否为空
get_model() {
  # local model_id=$(curl -s "$DEFAULT_MODELS_URL" | jq -r '.data[0].id')
  local model_id=$(curl -s "$DEFAULT_MODELS_URL" | grep -o '"id":[^,]*' | head -n1 | sed 's/.*"id":"\([^"]*\)".*/\1/')

  if [ -z "$model_id" ] || [ "$model_id" == "null" ]; then
    echo "⚠️  警告: 无法获取模型 ID，请检查 $DEFAULT_MODELS_URL 接口是否正常返回数据" >&2
    exit 1
  fi

  echo "$model_id"
}

# 发起 chat 请求
chat_request() {
  local url="${1:-$DEFAULT_URL}"
  local model="${2:-$(get_model)}"
  local prompt="${3:-$DEFAULT_MESSAGE}"
  local temperature="${4:-$DEFAULT_TEMP}"
  local stream="${5:-$DEFAULT_STREAM}"

  echo "✅ 使用模型: $model"

  local data=$(cat <<EOF
{
  "model": "$model",
  "messages": [
    {
      "role": "user",
      "content": "$prompt"
    }
  ],
  "temperature": $temperature,
  "stream": $stream
}
EOF
)

  curl -s -X POST "$url" \
    -H "Content-Type: application/json" \
    -d "$data"
}

# 调用主函数
chat_request "$@"

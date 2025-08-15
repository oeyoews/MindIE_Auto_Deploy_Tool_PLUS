#!/bin/bash

# 默认配置参数（可通过传参覆盖）
# HOST="${1:-localhost}"
# PORT="${2:-8000}"
# MODEL_NAME="${3:-Qwen/Qwen2-0.5B-Instruct}"  # 默认模型名称，可替换

HOST="192.168.1.100"
PORT="1025"
MODEL_NAME="qwen-7b"  # 默认模型名称，可替换
REQUEST_TYPE="Content-Type: application/json"

# 构造 URL
URL="http://${HOST}:${PORT}/v1/chat/completions"

# 构造请求 JSON
read -r -d '' PAYLOAD <<EOF
{
  "model": "${MODEL_NAME}",
  "messages": [
    {
      "role": "user",
      "content": "介绍一下你自己"
    }
  ],
  "temperature": 0.3,
  "stream": false
}
EOF

# 发送 POST 请求
curl -X POST "$URL" \
  -H "$REQUEST_TYPE" \
  -d "$PAYLOAD"

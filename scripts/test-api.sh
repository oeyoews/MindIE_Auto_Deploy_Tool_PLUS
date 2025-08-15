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

# 定义变量，用于存储解析后的参数
URL=""
MODEL=""
PROMPT=""
TEMPERATURE=""
STREAM=""

# 获取模型 ID，并检查是否为空
get_model() {
    # 优先使用用户指定的模型ID
    if [ ! -z "$MODEL" ]; then
        echo "$MODEL"
        return
    fi
    # 如果用户未指定，则从接口获取
    local model_id=$(curl -s "$DEFAULT_MODELS_URL" | grep -o '"id":[^,]*' | head -n1 | sed 's/.*"id":"\([^"]*\)".*/\1/')

    if [ -z "$model_id" ] || [ "$model_id" == "null" ]; then
        echo "⚠️  警告: 无法获取模型 ID，请检查 $DEFAULT_MODELS_URL 接口是否正常返回数据" >&2
        exit 1
    fi

    echo "$model_id"
}

# 解析命令行参数
# 长选项：url, model, prompt, temp, stream
# 短选项：u, m, p, t, s
OPTS=$(getopt -o u:m:p:t:s:h --long url:,model:,prompt:,temp:,stream:,help -n 'chat_request' -- "$@")

if [ $? != 0 ]; then
    echo "⚠️  错误: 参数解析失败。使用 -h 或 --help 查看帮助。" >&2
    exit 1
fi

eval set -- "$OPTS"

# 循环处理解析后的参数
while true; do
    case "$1" in
        -u|--url)
            URL="$2"
            shift 2
            ;;
        -m|--model)
            MODEL="$2"
            shift 2
            ;;
        -p|--prompt)
            PROMPT="$2"
            shift 2
            ;;
        -t|--temp)
            TEMPERATURE="$2"
            shift 2
            ;;
        -s|--stream)
            STREAM="$2"
            shift 2
            ;;
        -h|--help)
            echo "用法: chat_request.sh [选项]"
            echo ""
            echo "  -u, --url <URL>           指定聊天补全接口的URL (默认: $DEFAULT_URL)"
            echo "  -m, --model <ID>          指定要使用的模型ID (默认: 自动从 /v1/models 获取)"
            echo "  -p, --prompt <文本>         指定用户输入消息 (默认: '$DEFAULT_MESSAGE')"
            echo "  -t, --temp <值>           指定温度参数 (默认: $DEFAULT_TEMP)"
            echo "  -s, --stream <true|false> 指定是否流式返回结果 (默认: $DEFAULT_STREAM)"
            echo "  -h, --help                显示帮助信息"
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "⚠️  错误: 无法识别的参数 '$1'。使用 -h 或 --help 查看帮助。" >&2
            exit 1
            ;;
    esac
done

# 发起 chat 请求
chat_request() {
    # 如果用户没有指定，则使用默认值
    local url="${URL:-$DEFAULT_URL}"
    local model="$(get_model)"
    local prompt="${PROMPT:-$DEFAULT_MESSAGE}"
    local temperature="${TEMPERATURE:-$DEFAULT_TEMP}"
    local stream="${STREAM:-$DEFAULT_STREAM}"

    echo "✅ 使用 URL: $url"
    echo "✅ 使用模型: $model"
    echo "✅ 使用提示语: '$prompt'"
    echo "✅ 使用温度: $temperature"
    echo "✅ 使用流式: $stream"

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
    # 调用 curl
    curl -s -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "$data"
}

# 调用主函数
chat_request "$@"
#!/bin/bash

#########################
###   测试模型服务接口  ####
#########################

# base URL
PORT=1025
BASE_URL="http://192.168.1.46:$PORT"

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

# 显示帮助信息
show_help() {
    echo "用法: $(basename "$0") [选项]"
    echo ""
    echo "这是一个用于测试大语言模型API的命令行工具。它支持类似于OpenAI的接口。"
    echo ""
    echo "选项:"
    echo "  -u, --url <URL>           指定聊天补全接口的URL。默认: $DEFAULT_URL"
    echo "  -m, --model <ID>          指定要使用的模型ID。默认: 自动从 /v1/models 接口获取"
    echo "  -p, --prompt <文本>         指定用户输入的消息。默认: '$DEFAULT_MESSAGE'"
    echo "  -t, --temp <值>           指定温度参数（0.0-1.0），控制生成文本的随机性。默认: $DEFAULT_TEMP"
    echo "  -s, --stream <true|false> 指定是否以流式方式返回结果。默认: $DEFAULT_STREAM"
    echo "  -h, --help                显示此帮助信息并退出"
    echo ""
    echo "示例:"
    echo "  $(basename "$0") -p '给我一个关于React Hooks的例子'"
    echo "  $(basename "$0") --model my_custom_model --temp 0.8"
    echo "  $(basename "$0") --help"
}

# 解析命令行参数
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
            show_help
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

# 控制打字机效果的函数
# 参数：要打印的字符串
typing_effect() {
    local text="$1"

    # 使用 `sed` 将 `\n` 转义序列转换为实际的换行符
    # 这一步是为了确保多余的转义字符被正确解析
    local formatted_text=$(echo -e "$text")

    # 按字符迭代
    for ((i=0; i<${#formatted_text}; i++)); do
        char="${formatted_text:i:1}"

        # 使用 %b 格式符，它可以解释转义序列
        # 并且为了避免在不同系统上出现乱码，使用 -v 将其作为变量传递
        printf "%b" "$char"

        # 暂停一小段时间，这里是 0.01 秒
        sleep 0.01
    done
}


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
    if [ "$stream" == "true" ]; then
        # 流式输出处理
        curl -s -X POST "$url" \
             -H "Content-Type: application/json" \
             -d "$data" | while IFS= read -r line; do
                # 过滤空行并检查是否是结束标记
                if [[ -z "$line" || "$line" =~ ^data:\ \[DONE\] ]]; then
                    continue
                fi

                # 使用 grep 和 sed 提取 content 字段
                local content=$(echo "$line" | grep -o '"content":"[^"]*"' | sed 's/.*"content":"\([^"]*\)".*/\1/')
                if [ ! -z "$content" ]; then
                    # 实时打印，-n 选项防止自动换行
                             # 对提取到的每一块内容应用打字机效果
                    typing_effect "$content"

                fi
            done
        # 流式结束后换行
        echo ""
    else
        # 非流式输出，一次性打印
        curl -s -X POST "$url" \
             -H "Content-Type: application/json" \
             -d "$data" | jq '.choices[0].message.content'
    fi
}

# 调用主函数
chat_request "$@"
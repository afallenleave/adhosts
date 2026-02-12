#!/usr/bin/env bash

# 输入文件处理
file="${1:-/dev/stdin}"

# 临时存储结果（用于去重）
declare -A results

# 1. 逐行读取逻辑（参考你提供的稳健写法）
while IFS= read -r line || [ -n "$line" ]; do
    # 去掉首尾空白
    l="${line#"${line%%[![:space:]]*}"}"
    l="${l%"${l##*[![:space:]]}"}"

    # 跳过空行或以 # 开头的注释行
    [[ -z "$l" || "${l:0:1}" == "#" ]] && continue

    # 拆分第一个词（通常是 IP）和 剩余部分（通常是域名）
    # 比如 "0.0.0.0 ads1.com ads2.com"
    first_word="${l%%[[:space:]]*}"
    rest_of_line="${l#*[[:space:]]}"

    # 处理逻辑：
    # 我们需要把 line 里的所有元素拆开看，哪个是 IP，哪个是域名
    # 为了方便，我们将 first_word 和 rest_of_line 放在一起处理
    for item in $first_word $rest_of_line; do
        # 过滤掉回环地址，不把它们当做拦截目标
        [[ "$item" == "0.0.0.0" || "$item" == "127.0.0.1" || "$item" == "::1" ]] && continue
        
        # 判断类型
        if [[ "$item" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            # IPv4
            results["- IP-CIDR,$item/32"]=1
        elif [[ "$item" == *:* ]]; then
            # IPv6
            results["- IP-CIDR,$item/128"]=1
        elif [[ "$item" == *"."* ]]; then
            # 包含点且不是 IP 的视为域名
            results["- DOMAIN,$item"]=1
        fi
    done
done < "$file"

# 2. 输出 YAML 格式
echo "#10007"
echo "#更新时间: $(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")"
echo "payload:"

# 排序输出，保证结果稳定且方便对比
IFS=$'\n' sorted_list=($(printf "%s\n" "${!results[@]}" | sort))
unset IFS

for entry in "${sorted_list[@]}"; do
    echo "$entry"
done

#!/usr/bin/env bash

# 输入文件处理
file="${1:-/dev/stdin}"

# 临时存储结果（用于去重）
declare -A results

# 1. 逐行读取逻辑（采用你提供的稳健写法）
while IFS= read -r line || [ -n "$line" ]; do
    # 去掉首尾空白
    l="${line#"${line%%[![:space:]]*}"}"
    l="${l%"${l##*[![:space:]]}"}"

    # --- 跳过逻辑 ---
    # 跳过空行或以 # 开头的行
    [[ -z "$l" || "${l:0:1}" == "#" ]] && continue

    # 跳过特定的开头部分（根据你的要求：包含 localhost, hostname, ip6 的行不做处理）
    [[ "$l" == *"localhost"* || "$l" == *"hostname"* || "$l" == *"ip6"* ]] && continue
    # ---------------

    # 拆分行（处理类似 0.0.0.0 domain.com 或 1.2.3.4 domain.com）
    first_word="${l%%[[:space:]]*}"
    rest_of_line="${l#*[[:space:]]}"

    # 将行内的所有词拆开处理
    for item in $first_word $rest_of_line; do
        # 只要是 0.0.0.0 就跳过（不作为拦截目标，只看它后面的域名）
        [[ "$item" == "0.0.0.0" ]] && continue
        
        # 判断类型
        if [[ "$item" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            # IPv4：直接转为 /32（不额外过滤 127.*，尊重原始数据）
            results["- IP-CIDR,$item/32"]=1
        elif [[ "$item" == *:* ]]; then
            # IPv6：直接转为 /128
            results["- IP-CIDR,$item/128"]=1
        elif [[ "$item" == *"."* ]]; then
            # 域名：包含点号即视为域名（包括你提到的 http:// 那一行也会按原样处理）
            results["- DOMAIN,$item"]=1
        fi
    done
done < "$file"

# 2. 输出转换后的 YAML
echo "#10007"
echo "#更新时间: $(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")"
echo "payload:"

# 排序输出，保证结果稳定
IFS=$'\n' sorted_list=($(printf "%s\n" "${!results[@]}" | sort))
unset IFS

for entry in "${sorted_list[@]}"; do
    echo "$entry"
done

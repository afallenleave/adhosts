#!/usr/bin/env bash
file="${1:-/dev/stdin}"
echo "#10007"
echo "#更新时间: $(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")"
echo "payload:"
awk '
  /^[[:space:]]*#/ || /^[[:space:]]*$/ || /127.0.0.1/ || /0.0.0.0/ || /::1/ {next}
  {
    for(i=1; i<=NF; i++) {
        item = $i
        if (item ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
            results["- IP-CIDR," item "/32"] = 1
        } else if (item ~ /:/) {
            results["- IP-CIDR," item "/128"] = 1
        } else if (item ~ /\./) {
            results["- DOMAIN," item] = 1
        }
    }
  }
  END {
    n = asorti(results, sorted_list)
    for (i=1; i<=n; i++) print sorted_list[i]
  }
' "$file"

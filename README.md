# 自动转化10007大佬的hosts
rule-providers:
  10007-ads:
    type: http
    behavior: domain
    # 这里建议用 jsDelivr 的格式
    url: "https://cdn.jsdelivr.net/gh/afallenleave/adhosts@main/10007.yaml"
    path: ./ruleset/10007.yaml
    interval: 86400  # 每天检查一次更新

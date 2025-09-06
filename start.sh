#!/bin/sh

set -e

# 开启 IP 转发 (对于代理和路由是必要的)
echo "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1

# 启动代理服务（后台运行）
echo "Starting Tinyproxy..."
tinyproxy -c /etc/tinyproxy/tinyproxy.conf &

echo "Starting Dante SOCKS server..."
sockd -f /etc/sockd.conf &

# 检查必要的 VPN 环境变量
if [ -z "$VPN_SERVER" ] || [ -z "$VPN_USERNAME" ] || [ -z "$VPN_PASSWORD" ]; then
  echo "错误：VPN_SERVER, VPN_USERNAME, 和 VPN_PASSWORD 环境变量必须设置。"
  exit 1
fi

# 如果 SPLIT_ROUTES 环境变量未设置，则给一个空值
SPLIT_ROUTES_CMD=""
if [ -n "$SPLIT_ROUTES" ]; then
  # 关键改动：构建 vpn-slice 命令
  # -s 参数后面跟的是一个完整的命令字符串
  SPLIT_ROUTES_CMD="-s \"/usr/local/bin/vpn-slice ${SPLIT_ROUTES}\""
  echo "分流规则已启用。规则: ${SPLIT_ROUTES}"
else
  echo "未提供 SPLIT_ROUTES，所有流量将通过 VPN。"
fi

# 使用无限循环来实现 VPN 连接的保活（断线自动重连）
while true; do
  echo "尝试连接到 VPN 服务器: $VPN_SERVER..."
  
  # 启动 OpenConnect（前台运行）
  # --script 参数会在连接成功后执行我们的路由脚本
  echo "$VPN_PASSWORD" | openconnect $VPN_SERVER \
    -m 1290 \
    -u "$VPN_USERNAME" \
    --passwd-on-stdin \
    --useragent "AnyConnect whatever" \

  # 如果 openconnect 进程退出（例如断线或服务器问题），循环会继续
  echo "VPN 已断开。将在 10 秒后尝试重新连接..."
  sleep 10
done

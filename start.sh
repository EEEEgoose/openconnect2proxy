#!/bin/sh

# 开启 IP 转发
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

# 启动 OpenConnect（前台运行）
# 使用 exec 将 shell 进程替换为 openconnect 进程
# 这样可以确保容器的信号能被正确传递给 openconnect
echo "Starting OpenConnect to $VPN_SERVER..."
exec echo "$VPN_PASSWORD" | openconnect $VPN_SERVER --non-inter -u "$VPN_USERNAME" --passwd-on-stdin

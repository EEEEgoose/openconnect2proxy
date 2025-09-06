# 使用一个非常小的 Alpine Linux 作为基础镜像
FROM alpine:3.20

# 维护者标签
LABEL maintainer="EEEEgoose"

# 设置默认端口环境变量
ENV TINYPROXY_PORT=8888
ENV DANTE_PORT=1080

# 安装所有需要的软件包，并清理缓存以减小镜像体积
# tini 是一个简单的 init 系统，用于处理僵尸进程和信号转发，是 Docker 最佳实践
RUN apk add --no-cache \
    openconnect \
    tini \
    tinyproxy \
    dante-server

# 复制配置文件
COPY config/tinyproxy.conf /etc/tinyproxy/tinyproxy.conf
COPY config/sockd.conf /etc/sockd.conf

# 复制并设置启动脚本
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 暴露代理端口
EXPOSE ${TINYPROXY_PORT}
EXPOSE ${DANTE_PORT}

# 设置容器的入口点和默认命令
# tini 将作为 PID 1 进程，并启动我们的 start.sh 脚本
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/start.sh"]

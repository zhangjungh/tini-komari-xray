FROM debian:bookworm-slim

# 安装基础工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends tini curl ca-certificates jq && \
    rm -rf /var/lib/apt/lists/*

# 安装 xray-core
ENV XRAY_VERSION=25.4.0
RUN curl -L -o xray.zip "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-64.zip" && \
    unzip xray.zip && \
    mv xray /usr/local/bin/ && \
    chmod +x /usr/local/bin/xray && \
    rm xray.zip

# 安装 komari-agent
RUN curl -L -o /usr/local/bin/komari-agent https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-linux-amd64 && \
    chmod +x /usr/local/bin/komari-agent

# 复制启动脚本和示例配置
COPY start.sh /start.sh
COPY xray-config.example.json /etc/xray/config.example.json
RUN chmod +x /start.sh

# 声明环境变量（用于文档和默认值）
ENV KOMARI_SERVER=""
ENV KOMARI_TOKEN=""
ENV XRAY_UUID=""
ENV XRAY_PORT="443"

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/start.sh"]

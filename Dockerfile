FROM debian:bookworm-slim

# 安装依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends tini curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# 下载 xray-core（使用稳定版本）
ENV XRAY_VERSION=25.4.0
RUN curl -L -o xray.zip "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-64.zip" && \
    unzip xray.zip && \
    mv xray /usr/local/bin/ && \
    chmod +x /usr/local/bin/xray && \
    rm xray.zip

# 下载 komari-agent（从官方 GitHub Releases）
RUN curl -L -o /usr/local/bin/komari-agent https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-linux-amd64 && \
    chmod +x /usr/local/bin/komari-agent

# 复制配置与脚本
COPY xray-config.json /etc/xray/config.json
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 声明环境变量（便于文档和默认值）
ENV KOMARI_SERVER=""
ENV KOMARI_TOKEN=""

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/start.sh"]

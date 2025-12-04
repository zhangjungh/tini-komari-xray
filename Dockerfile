# 使用多阶段方式更清晰（可选），但这里用单阶段
FROM debian:bookworm-slim

# 安装基础工具（用于后续判断架构和下载）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tini curl ca-certificates jq wget \
    && rm -rf /var/lib/apt/lists/*

# 安装 dpkg（用于获取目标架构）
RUN apt-get update && \
    apt-get install -y --no-install-recommends dpkg \
    && rm -rf /var/lib/apt/lists/*

# 根据目标系统架构下载 xray-core
ENV XRAY_VERSION=25.12.2
RUN ARCH=$(dpkg --print-architecture); \
    if [ "$ARCH" = "amd64" ]; then \
        XRAY_ARCH="64"; \
    elif [ "$ARCH" = "arm64" ]; then \
        XRAY_ARCH="arm64-v8a"; \
    else \
        echo "Unsupported architecture: $ARCH" >&2; exit 1; \
    fi; \
    echo "Building for architecture: $ARCH (Xray arch: $XRAY_ARCH)"; \
    curl -L -o xray.zip "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${XRAY_ARCH}.zip" && \
    unzip xray.zip && \
    mv xray /usr/local/bin/ && \
    chmod +x /usr/local/bin/xray && \
    rm xray.zip

# 下载 komari-agent
RUN ARCH=$(dpkg --print-architecture); \
    if [ "$ARCH" = "amd64" ]; then \
        KOMARI_ARCH="linux-amd64"; \
    elif [ "$ARCH" = "arm64" ]; then \
        KOMARI_ARCH="linux-arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" >&2; exit 1; \
    fi; \
    echo "Downloading komari-agent for: $KOMARI_ARCH"; \
    curl -L -o /usr/local/bin/komari-agent "https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-${KOMARI_ARCH}" && \
    chmod +x /usr/local/bin/komari-agent

# 复制启动脚本和配置
COPY start.sh /start.sh
COPY xray-config.example.json /etc/xray/config.example.json
RUN chmod +x /start.sh

# 环境变量
ENV KOMARI_SERVER=""
ENV KOMARI_TOKEN=""
ENV XRAY_UUID=""
ENV XRAY_PORT="443"

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/start.sh"]

FROM debian:bookworm-slim

# 安装运行时依赖（tini, ca-certificates, jq）
RUN apt-get update && \
    apt-get install -y --no-install-recommends tini ca-certificates jq && \
    rm -rf /var/lib/apt/lists/*

# 安装构建时依赖（仅用于下载，后续可清理）
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl unzip && \
    rm -rf /var/lib/apt/lists/*

# === 下载 xray-core（根据 TARGETPLATFORM 自动选择架构）===
# 注意：TARGETPLATFORM 是 BuildKit 自动设置的，如 "linux/amd64"
ENV XRAY_VERSION=25.12.2
RUN case "$TARGETPLATFORM" in \
        "linux/amd64")   ARCH="64" ;; \
        "linux/arm64")   ARCH="arm64-v8a" ;; \
        *) echo "Unsupported platform: $TARGETPLATFORM" >&2; exit 1 ;; \
    esac && \
    echo "Downloading Xray for $TARGETPLATFORM -> arch: $ARCH" && \
    curl -L -o xray.zip "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${ARCH}.zip" && \
    unzip xray.zip && \
    mv xray /usr/local/bin/xray && \
    chmod +x /usr/local/bin/xray && \
    rm xray.zip

# === 下载 komari-agent ===
RUN case "$TARGETPLATFORM" in \
        "linux/amd64")   ARCH="linux-amd64" ;; \
        "linux/arm64")   ARCH="linux-arm64" ;; \
        *) echo "Unsupported platform: $TARGETPLATFORM" >&2; exit 1 ;; \
    esac && \
    echo "Downloading komari-agent for $TARGETPLATFORM -> $ARCH" && \
    curl -L -o /usr/local/bin/komari-agent "https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-${ARCH}" && \
    chmod +x /usr/local/bin/komari-agent

# 清理构建依赖（减小镜像体积）
RUN apt-get update && \
    apt-get purge -y --auto-remove curl unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 复制应用文件
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

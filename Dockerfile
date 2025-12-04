FROM debian:bookworm-slim

# 👇 必须先声明 ARG！
ARG TARGETPLATFORM

# 安装依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends tini ca-certificates jq curl unzip && \
    rm -rf /var/lib/apt/lists/*

# 下载 xray-core
ENV XRAY_VERSION=25.12.2
RUN case "$TARGETPLATFORM" in \
        "linux/amd64")   ARCH="64" ;; \
        "linux/arm64")   ARCH="arm64-v8a" ;; \
        *) echo "ERROR: Unsupported TARGETPLATFORM: '$TARGETPLATFORM'" >&2; exit 1 ;; \
    esac && \
    echo "Downloading Xray for $TARGETPLATFORM (arch: $ARCH)" && \
    curl -fsSL -o xray.zip "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${ARCH}.zip" && \
    unzip xray.zip && \
    mv xray /usr/local/bin/xray && \
    chmod +x /usr/local/bin/xray && \
    rm xray.zip

# 下载 komari-agent
RUN case "$TARGETPLATFORM" in \
        "linux/amd64")   ARCH="linux-amd64" ;; \
        "linux/arm64")   ARCH="linux-arm64" ;; \
        *) echo "ERROR: Unsupported TARGETPLATFORM: '$TARGETPLATFORM'" >&2; exit 1 ;; \
    esac && \
    echo "Downloading komari-agent for $TARGETPLATFORM" && \
    curl -fsSL -o /usr/local/bin/komari-agent "https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-${ARCH}" && \
    chmod +x /usr/local/bin/komari-agent

# 清理
RUN apt-get purge -y --auto-remove curl unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY start.sh /start.sh
COPY xray-config.example.json /etc/xray/config.example.json
RUN chmod +x /start.sh

ENV KOMARI_SERVER=""
ENV KOMARI_TOKEN=""
ENV XRAY_UUID=""
ENV XRAY_PORT="443"

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/start.sh"]

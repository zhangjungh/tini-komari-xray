FROM --platform=$BUILDPLATFORM debian:bookworm-slim

# 安装基础工具（在构建平台运行）
RUN apt-get update && \
    apt-get install -y --no-install-recommends tini curl ca-certificates jq && \
    rm -rf /var/lib/apt/lists/*

# 根据目标架构下载对应二进制
ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH}

# 下载 xray-core（根据架构选择）
ENV XRAY_VERSION=25.12.2
RUN case "$TARGETARCH" in \
        "amd64") XRAY_ARCH="64" ;; \
        "arm64") XRAY_ARCH="arm64-v8a" ;; \
        *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac && \
    curl -L -o xray.zip "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${XRAY_ARCH}.zip" && \
    unzip xray.zip && \
    mv xray /usr/local/bin/ && \
    chmod +x /usr/local/bin/xray && \
    rm xray.zip

# 下载 komari-agent（根据架构选择）
RUN case "$TARGETARCH" in \
        "amd64") KOMARI_ARCH="linux-amd64" ;; \
        "arm64") KOMARI_ARCH="linux-arm64" ;; \
        *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac && \
    curl -L -o /usr/local/bin/komari-agent "https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-${KOMARI_ARCH}" && \
    chmod +x /usr/local/bin/komari-agent

# 复制启动脚本和示例配置
COPY start.sh /start.sh
COPY xray-config.example.json /etc/xray/config.example.json
RUN chmod +x /start.sh

# 声明环境变量
ENV KOMARI_SERVER=""
ENV KOMARI_TOKEN=""
ENV XRAY_UUID=""
ENV XRAY_PORT="443"

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/start.sh"]

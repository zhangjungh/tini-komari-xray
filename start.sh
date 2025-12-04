#!/bin/bash
set -e

# ===========================
# 1. 处理 Xray 配置
# ===========================
XRAY_CONFIG=""

# 优先：检查是否挂载了有效配置文件
if [ -f "/etc/xray/config.json" ] && [ -s "/etc/xray/config.json" ]; then
    if jq empty /etc/xray/config.json >/dev/null 2>&1; then
        XRAY_CONFIG="/etc/xray/config.json"
        echo "✅ Using mounted xray config: /etc/xray/config.json"
    else
        echo "❌ Mounted config is not valid JSON. Ignoring."
    fi
fi

# 回退：用环境变量生成简单配置
if [ -z "$XRAY_CONFIG" ] && [ -n "$XRAY_UUID" ]; then
    echo "📝 Generating xray config from environment variables..."
    cat > /tmp/xray-generated.json <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": ${XRAY_PORT},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$XRAY_UUID"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF
    XRAY_CONFIG="/tmp/xray-generated.json"
    echo "✅ Generated config: $XRAY_CONFIG"
fi

# 最终检查
if [ -z "$XRAY_CONFIG" ]; then
    echo "❌ No valid xray configuration found!" >&2
    echo "👉 Either mount a config to /etc/xray/config.json" >&2
    echo "👉 Or set XRAY_UUID (and optionally XRAY_PORT)" >&2
    exit 1
fi

# ===========================
# 2. 启动 komari-agent（后台）
# ===========================
KOMARI_ARGS=""
if [ -n "$KOMARI_SERVER" ]; then
    KOMARI_ARGS="$KOMARI_ARGS -e $KOMARI_SERVER"
fi
if [ -n "$KOMARI_TOKEN" ]; then
    KOMARI_ARGS="$KOMARI_ARGS -t $KOMARI_TOKEN"
fi

if [ -n "$KOMARI_ARGS" ]; then
    echo "🚀 Starting komari-agent with args: $KOMARI_ARGS"
    komari-agent $KOMARI_ARGS &
else
    echo "⚠️  Warning: KOMARI_SERVER or KOMARI_TOKEN not set"
    komari-agent &
fi

# ===========================
# 3. 启动 xray-core（前台）
# ===========================
echo "🔌 Starting xray-core with config: $XRAY_CONFIG"
exec xray -config "$XRAY_CONFIG"

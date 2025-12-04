#!/bin/bash
set -e

# ===== 新增：动态生成 Xray 配置 =====
if [ -n "$XRAY_UUID" ] || [ -n "$XRAY_PORT" ]; then
  echo "Generating xray config from env vars..."
  cat > /tmp/xray-generated.json <<EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "port": ${XRAY_PORT:-443},
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "$XRAY_UUID"}],
      "decryption": "none"
    },
    "streamSettings": {"network": "tcp"}
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF
  XRAY_CONFIG="/tmp/xray-generated.json"
else
  XRAY_CONFIG="/etc/xray/config.json"
fi
# ===== 配置生成结束 =====

# 启动 komari-agent（同前）
komari-agent ${KOMARI_SERVER:+ -e $KOMARI_SERVER} ${KOMARI_TOKEN:+ -t $KOMARI_TOKEN} &

# 启动 xray
exec xray -config "$XRAY_CONFIG"

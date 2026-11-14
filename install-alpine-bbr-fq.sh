#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ] || [ ! -f /etc/alpine-release ]; then
    echo '请在 Alpine Linux 上以 root 运行。' >&2
    exit 1
fi

iface=${1:-eth0}
case "$iface" in
    *[!a-zA-Z0-9_.:-]*) echo '网卡名包含不支持的字符。' >&2; exit 1 ;;
esac
if [ "$#" -gt 1 ] || [ ! -d "/sys/class/net/$iface" ] || [ "$iface" = lo ]; then
    echo "用法：sh install-alpine-bbr-fq.sh [现有网卡名]（默认 eth0）" >&2
    exit 1
fi

if ! command -v rc-update >/dev/null 2>&1 || [ ! -x /etc/init.d/local ]; then
    echo '此脚本需要 Alpine 的 OpenRC 和 local 服务。' >&2
    exit 1
fi

if ! command -v tc >/dev/null 2>&1; then
    apk add iproute2-tc
fi

modprobe tcp_bbr 2>/dev/null || true
modprobe sch_fq 2>/dev/null || true
sysctl -w net.core.default_qdisc=fq
sysctl -w net.ipv4.tcp_congestion_control=bbr

# Replace the selected interface's root queue immediately.
tc qdisc replace dev "$iface" root fq

mkdir -p /etc/sysctl.d
cat > /etc/sysctl.d/99-bbr.conf <<'EOF'
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

# Apply the settings again after OpenRC brings up networking.
mkdir -p /etc/local.d
cat > /etc/local.d/alpine-bbr-fq.start <<EOF
#!/bin/sh
set -e
modprobe tcp_bbr 2>/dev/null || true
modprobe sch_fq 2>/dev/null || true
sysctl -p /etc/sysctl.d/99-bbr.conf
tc qdisc replace dev '$iface' root fq
EOF
chmod 755 /etc/local.d/alpine-bbr-fq.start
rc-update add local default

sysctl net.ipv4.tcp_congestion_control net.core.default_qdisc
tc qdisc show dev "$iface"

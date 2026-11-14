# Alpine BBR + fq

## 一键安装

在 Alpine 上以 `root` 执行下面的命令，默认配置 `eth0`。

```sh
wget -O /tmp/install-alpine-bbr-fq.sh https://raw.githubusercontent.com/brian952700/alpine-bbr-fq/main/install-alpine-bbr-fq.sh && sh /tmp/install-alpine-bbr-fq.sh
```

使用其他网卡时，在命令末尾加上网卡名，例如 `ens3`。

[下载安装脚本](https://raw.githubusercontent.com/brian952700/alpine-bbr-fq/main/install-alpine-bbr-fq.sh)

## 本地运行

在使用 OpenRC 的 Alpine Linux 上启用 TCP BBR，并将指定网卡的根队列切换为 `fq`。默认网卡为 `eth0`。

以 root 在仓库目录下执行：

```sh
sh install-alpine-bbr-fq.sh
```

使用其他网卡时，把网卡名作为参数传入：

```sh
sh install-alpine-bbr-fq.sh ens3
```

脚本按需安装 `iproute2-tc`，写入 `/etc/sysctl.d/99-bbr.conf`，并用 OpenRC 的 `local` 服务在开机时重新应用设置。运行前请确认目标网卡的现有根队列可以被替换，已有的流量整形规则可能随根队列一起移除。

重启后可执行以下命令验证（将 `eth0` 换成实际网卡名）：

```sh
sysctl net.ipv4.tcp_congestion_control net.core.default_qdisc
tc qdisc show dev eth0
```

预期分别显示 `bbr`、`fq`，以及以 `qdisc fq` 开头的队列信息。

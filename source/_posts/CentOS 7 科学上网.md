---
layout: post
title: CentOS 7 科学上网
date: 2019-05-16 10:11:00
tags: 
  - CentOS
  - 代理
---

### 搭建 Shadowsocks 代理服务器

关于代理服务器详细可见:[Proxy Server](https://en.wikipedia.org/wiki/Proxy_server)

整理下日常使用过代理的各种方式

### 使用 Shadowsocks 实现代理服务器

[shadowsocks]([https://github.com/shadowsocks]),各种语言的版本都有.这里以[shadowsocks-libev](/)为例.

1. 从源构建：
   下载当前最新发行版:[shadowsocks-libev-3.2.5.tar.gz](https://github.com/shadowsocks/shadowsocks-libev/releases/download/v3.2.5/shadowsocks-libev-3.2.5.tar.gz)

```bash
tar -xvf shadowsocks-libev-3.2.5.tar.gz

# 安装构建依赖
yum install epel-release -y
yum install gcc gettext autoconf libtool \
automake make pcre-devel asciidoc xmlto \
c-ares-devel libev-devel libsodium-devel mbedtls-devel -y

# 安装
cd shadowsocks-libev-3.2.5
./configure  # 可以 --help 查看更多选项
make
make install
```

2. 运行

```bash
ls /usr/local/bin/ | grep ss-
```

3. 可以看到:

```bash
ss-local
ss-manager
ss-nat
ss-redir
ss-server
ss-tunnel
```

4. 创建 ss 服务器配置:

```bash
mkdir -p /etc/shadowsocks-libev
touch /etc/shadowsocks-libev/ss-server.json
cat <<EOF >> /etc/shadowsocks-libev/ss-server.json
{
    "server": "0.0.0.0",
    "port_password": { # 一端口一密码
        "12306": "foobar1",
        "12307": "foobar2",
    },
    "timeout": 300,
    "method": "aes-256-cfb"
}
EOF
```

5. 启动服务

```bash
nohup ss-server -c /etc/shadowsocks-libev/ss-server.json &>/dev/null &
```
也可以使用[systemd](https://www.freedesktop.org/wiki/Software/systemd/)，实现开机启动(貌似不大需要).
 
除了从源码构建，更方便的方式是使用yum源安装。shadowsocks-libev在[Fedora Copr]("https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/")上有repo文件。我们只需要下载到/etc/yum.repos.d/然后用yum安装就行了。:
```sh
cd /etc/yum.repos.d/
wget https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-7/librehat-shadowsocks-epel-7.repo
yum clean all
yum makecache
yum install shadowsocks-libev -y
```
可能需要手动安装的依赖:
```
wget http://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/m/mbedtls-2.7.12-1.el7.x86_64.rpm

wget http://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/l/libsodium-1.0.18-1.el7.x86_64.rpm

rpm -Uvh *.rpm
```

### 客户端使用
安装过程同上。
1. 创建客户端配置文件:

```bash
# ss-client.json
{
    "server": "my_server_ip",
    "server_port": 12306,
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "password": "foobar1",
    "timeout": 300,
    "method": "aes-256-cfb",
    "fast_open": false
}
```

2. 客户端启动:

```bash
nohup ss-local -c ss-client.json &>/dev/null &
```

### 使用 privoxy 实现 HTTP 代理

安装编译工具

```bash
yum groupinstall "Development Tools"
```

下载 privoxy 最新版
[http://sourceforge.net/projects/ijbswa/files/Sources/](http://sourceforge.net/projects/ijbswa/files/Sources/)

编译

```bash
tar xzvf privoxy-3.0.23-stable-src.tar.gz
cd privoxy-3.0.23-stable
autoheader
autoconf
./configure      # (--help to see options)
make             # (the make from GNU, sometimes called gmake)
```

privoxy 文档建议使用非 root 用户运行,建立账户

```bash
sudo useradd privoxy -r -s /usr/sbin/nologin
```

安装

```bash
sudo make install
```

更改侦听地址

```bash
vi /usr/local/etc/privoxy/config
```

将 listen-address 值更改为 0.0.0.0:8118

重启

```bash
systemctl restart privoxy
```

打开防火墙端口

```bash
firewall-cmd --permanent --add-port=8118/tcp
firewall-cmd --reload
```

范例配置(使用本地 socks5 上级代理，本地地址不走代理)

```bash
vi /usr/local/etc/privoxy/config
```

增加

```bash
forward-socks5 / 127.0.0.1:1080 .
forward 10.*.*.*/ .
forward 192.168.*.*/ .
forward 127.*.*.*/ .
forward localhost/ .
```
systemctl重启 privoxy

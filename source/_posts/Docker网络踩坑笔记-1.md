---
layout: post
title: Docker网络踩坑笔记(1)
date: 2019-05-24 18:28:43
tags:
  - Docker
  - Kubernetes
---

最近想使用k8s管理微服务集群，由于是从单纯的Docker移植，加上对于k8s也是新手难免遇到了各种问题，好在都一一克服了。经历过就了解了，记录一下。

Linux [iptables](https://wiki.archlinux.org/index.php/Iptables_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)) 是一个配置 Linux 内核 防火墙 的命令行工具(用于ipv4)，是 `netfilter` 项目的一部分。
Docker 容器(containers) 及 服务(services)如此强大的原因之一是它们相互之间可以互联或者连接到非Docker负载。在Linux上Docker通过操作的iptables规则来实现这种复杂的容器网络。

默认 docker continer 的网络是走的 nat. 一般选择的是 172.17.0.0/16 段，大部分情况下这个内网网段未使用. 启动 docker 时会在宿主机的 nat表 和 filter表 自动添加一些规则.
在某台服务器上运行:
```bash
iptables -t nat -L -nv
```
一般可以看到:
```bash
Chain PREROUTING (policy ACCEPT 244K packets, 15M bytes)
 pkts bytes target     prot opt in     out     source               destination         
 287K   17M DOCKER     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL

Chain INPUT (policy ACCEPT 244K packets, 15M bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 230K packets, 14M bytes)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 DOCKER     all  --  *      *       0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL

Chain POSTROUTING (policy ACCEPT 231K packets, 14M bytes)
 pkts bytes target     prot opt in     out     source               destination         
 1656 89798 MASQUERADE  all  --  *      !br-96a729b6b174  172.19.0.0/16        0.0.0.0/0           
    0     0 MASQUERADE  all  --  *      !docker0  172.18.0.0/16        0.0.0.0/0           
    0     0 MASQUERADE  all  --  *      !br-2752d520c67d  172.21.0.0/16        0.0.0.0/0           
    0     0 MASQUERADE  all  --  *      !br-08d32297f556  172.20.0.0/16        0.0.0.0/0           
    0     0 MASQUERADE  all  --  *      !br-df07ce3e6f03  172.22.0.0/16        0.0.0.0/0           
    0     0 MASQUERADE  all  --  *      !br-6052a0c8ee6f  172.24.0.0/16        0.0.0.0/0           
    0     0 MASQUERADE  all  --  *      !br-3e981750d170  172.23.0.0/16        0.0.0.0/0           
    0     0 MASQUERADE  tcp  --  *      *       172.19.0.2           172.19.0.2           tcp dpt:443
    0     0 MASQUERADE  tcp  --  *      *       172.19.0.2           172.19.0.2           tcp dpt:80
    0     0 MASQUERADE  tcp  --  *      *       172.19.0.2           172.19.0.2           tcp dpt:22
    0     0 MASQUERADE  tcp  --  *      *       172.19.0.4           172.19.0.4           tcp dpt:3000
    0     0 MASQUERADE  tcp  --  *      *       172.19.0.6           172.19.0.6           tcp dpt:6379
    0     0 MASQUERADE  tcp  --  *      *       172.19.0.7           172.19.0.7           tcp dpt:8082
    0     0 MASQUERADE  tcp  --  *      *       172.19.0.8           172.19.0.8           tcp dpt:3001
    0     0 MASQUERADE  tcp  --  *      *       172.19.0.9           172.19.0.9           tcp dpt:80
    0     0 MASQUERADE  tcp  --  *      *       172.19.0.10          172.19.0.10          tcp dpt:639
    0     0 MASQUERADE  tcp  --  *      *       172.19.0.10          172.19.0.10          tcp dpt:389
    0     0 MASQUERADE  tcp  --  *      *       172.19.0.11          172.19.0.11          tcp dpt:80
    0     0 MASQUERADE  tcp  --  *      *       172.19.0.15          172.19.0.15          tcp dpt:443
    0     0 MASQUERADE  tcp  --  *      *       172.19.0.15          172.19.0.15          tcp dpt:80

Chain DOCKER (2 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 RETURN     all  --  br-96a729b6b174 *       0.0.0.0/0            0.0.0.0/0           
    0     0 RETURN     all  --  docker0 *       0.0.0.0/0            0.0.0.0/0           
    0     0 RETURN     all  --  br-2752d520c67d *       0.0.0.0/0            0.0.0.0/0           
    0     0 RETURN     all  --  br-08d32297f556 *       0.0.0.0/0            0.0.0.0/0           
    0     0 RETURN     all  --  br-df07ce3e6f03 *       0.0.0.0/0            0.0.0.0/0           
    0     0 RETURN     all  --  br-6052a0c8ee6f *       0.0.0.0/0            0.0.0.0/0           
    0     0 RETURN     all  --  br-3e981750d170 *       0.0.0.0/0            0.0.0.0/0           
    0     0 DNAT       tcp  --  !br-96a729b6b174 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:20443 to:172.19.0.2:443
    0     0 DNAT       tcp  --  !br-96a729b6b174 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:20080 to:172.19.0.2:80
   68  2924 DNAT       tcp  --  !br-96a729b6b174 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:23 to:172.19.0.2:22
    0     0 DNAT       tcp  --  !br-96a729b6b174 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:3002 to:172.19.0.4:3000
    2   100 DNAT       tcp  --  !br-96a729b6b174 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:6379 to:172.19.0.6:6379
    0     0 DNAT       tcp  --  !br-96a729b6b174 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8081 to:172.19.0.7:8082
    0     0 DNAT       tcp  --  !br-96a729b6b174 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:3001 to:172.19.0.8:3001
   11   624 DNAT       tcp  --  !br-96a729b6b174 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8088 to:172.19.0.9:80
    1    40 DNAT       tcp  --  !br-96a729b6b174 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:639 to:172.19.0.10:639
    0     0 DNAT       tcp  --  !br-96a729b6b174 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:389 to:172.19.0.10:389
    4   200 DNAT       tcp  --  !br-96a729b6b174 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 to:172.19.0.11:80
   12   652 DNAT       tcp  --  !br-96a729b6b174 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:443 to:172.19.0.15:443
   13   688 DNAT       tcp  --  !br-96a729b6b174 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:80 to:172.19.0.15:80
```
这种默认的网络配置可以让用户无需关心docker网络.但是手动修改`iptables`规则时最好先用`iptables-save`备份,已防意外时可以快速使用`iptables-restore`恢复。

在宿主机上使用 ip addr 可以看到网络:
```bash
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:16:3e:0e:58:74 brd ff:ff:ff:ff:ff:ff
    inet 172.17.253.62/20 brd 172.17.255.255 scope global dynamic eth0
       valid_lft 311968443sec preferred_lft 311968443sec
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:4e:6f:a4:00 brd ff:ff:ff:ff:ff:ff
    inet 172.18.0.1/16 brd 172.18.255.255 scope global docker0
       valid_lft forever preferred_lft forever
3094: vethd17ce7f@if3093: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br-96a729b6b174 state UP group default 
    link/ether 2e:50:e7:1a:2f:5f brd ff:ff:ff:ff:ff:ff link-netnsid 8
3096: veth4cc5908@if3095: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br-96a729b6b174 state UP group default 
    link/ether 6e:b0:7b:c1:80:4f brd ff:ff:ff:ff:ff:ff link-netnsid 9

# 省略n行...
```
docker0是docker启动时在宿主机上创建的虚拟网络接口, 用来管理docker container的网络.
Docker 默认指定了 docker0 接口 的 IP 地址和子网掩码，让主机和容器之间可以通过网桥相互通信，它还给出了 MTU（接口允许接收的最大传输单元），通常是 1500 Bytes，或宿主主机网络路由上支持的默认值。这些值都可以在服务启动的时候进行配置.
- --bip=CIDR IP 地址加掩码格式，例如 192.168.1.5/24
- --mtu=BYTES 覆盖默认的 Docker mtu 配置
也可以在配置文件中配置 DOCKER_OPTS，然后重启服务。

由于当前 Docker 网桥是 Linux 网桥，使用 brctl show 来查看网桥和端口连接信息:
```bash
br-96a729b6b174         8000.0242129f14c0       no              veth3322438
                                                        veth4a5374d
                                                        veth4cc5908
                                                        veth5a6b910
                                                        veth66dae97
                                                        veth730d923
                                                        veth80c057a
                                                        vetha504b9c
                                                        vetha6e133c
                                                        vethb538581
                                                        vethb88ed80
                                                        vethcd6dfdd
                                                        vethd17ce7f
                                                        vethfcd565c
docker0         8000.02424e6fa400       no
```
每次创建一个新容器的时候，Docker 从可用的地址段中选择一个空闲的 IP 地址分配给容器的 eth0 端口。使用本地主机上 `docker0` 接口的 IP 作为所有容器的默认网关。

### 使用docker network管理网络
当`iptables`手动修改错误时,可能在重启某个container时出现如下:
```bash
03:49.547056143+08:00" level=warning msg="Failed to allocate and map 
port 20443-20443:  (iptables failed: iptables --wait -t nat -A DOCKER
-p tcp -d 0/0 --dport 20443 -j DNAT --to-destination 172.19.0.5:443 ! -i br-330809f39e04: 
iptables: No chain/--wait -t
```
一般情况是该容器在主机上的`iptables`规则被修改或删除了.
使用`docker network ls` 和 `docker inspect ${container_id}`确定容器所在的网络。
运行:`docker network connect ${container_id} ${network_name}`重新更新容器网络配置,iptables规则重新生成.

参考:
- [Docker Network](https://docs.docker.com/network/)
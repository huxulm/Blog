---
layout: post
title: kubespray(2.10.3)部署高可用Kubernetes集群
date: 2019-06-25 10:50:57
tags:
    - Kubernetes
---

![](/images/06-25/Affordable-Kubernetes.png)

Kubernetes集群部署方式很多，网上也有大量实践和文章。几种主要部署方式对比:
 
|部署方案|	优点|	缺点|
|-|-|-|
|[Kubeadm](https://github.com/kubernetes/kubeadm)|	官方出品|	部署较繁琐、不够透明|
|[Kubespray](https://kubespray.io)|	官方出品、部署较简单、懂Ansible就能上手|	不够透明|
|[RKE](https://github.com/rancher/rke)|	部署较简单、需要花一些时间了解RKE的cluster.yml配置文件|	不够透明|
|[手动部署](https://k8s-deploy.mzhpan.cn)| 第三方操作文档	完全透明、可配置、便于理解K8s各组件之间的关系|	部署过程很繁琐，容易出错


本文记录使用 [Kubespray 2.10.3](https://kubespray.io) 部署高可用Kubernetes集群。

### 主机准备
|主机名|IP|
|-|-|
|ha-k8s-001|192.168.1.113|
|ha-k8s-002|192.168.1.114|
|ha-k8s-003|192.168.1.115|

### 获取容器镜像
国内gcr.io、k8s.gcr.io都是不可达的，部署时会因为无法拉取镜像导致失败。这里的解决方案是通过VPS代理，在[GCP](https://console.cloud.google.com)将需要的镜像同步到国内。
kubespray需要的镜像地址在`roles/download/defaults/main.yml`可以找到。
同步脚本:`get_images.sh`
```bash
#!/usr/bin/env bash

ALIYUN_BASE_REPO="registry.cn-hangzhou.aliyuncs.com/brucexu"

# quay.io/coreos
images1=(
	etcd:v3.2.26
    flannel:v0.11.0
    flannel-cni:v0.3.0
)

for imageName in ${images1[@]} ; do
    docker pull quay.io/coreos/$imageName
    docker tag quay.io/coreos/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# docker.io/calico
images2=(
    node:v3.4.0
    cni:v3.4.0
    kube-controllers:v3.4.0
    routereflector:v0.6.1
    typha:v3.4.4
)

for imageName in ${images2[@]} ; do
    docker pull docker.io/calico/$imageName
    docker tag docker.io/calico/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# gcr.io/google_containers
images3=(
    pause-amd64:3.1
    kube-registry-proxy:0.4
    metrics-server-amd64:v0.3.2
    kubernetes-dashboard-amd64:v1.10.1
)

for imageName in ${images3[@]} ; do
    docker pull gcr.io/google_containers/$imageName
    docker tag gcr.io/google_containers/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# docker.io/xueshanf
images4=(
    install-socat:latest
)

for imageName in ${images4[@]} ; do
    docker pull docker.io/xueshanf/$imageName
    docker tag docker.io/xueshanf/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# quay.io/l23network
images5=(
    k8s-netchecker-agent:v1.0
    k8s-netchecker-server:v1.0
)

for imageName in ${images5[@]} ; do
    docker pull quay.io/l23network/$imageName
    docker tag quay.io/l23network/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done


# docker.io/weaveworks
images6=(
    weave-kube:2.5.1
    weave-npc:2.5.1
)

for imageName in ${images6[@]} ; do
    docker pull docker.io/weaveworks/$imageName
    docker tag docker.io/weaveworks/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# docker.io/contiv
images7=(
    netplugin:1.2.1
    netplugin-init:latest
    auth_proxy:1.2.1
    ovs:latest
)

for imageName in ${images7[@]} ; do
    docker pull docker.io/contiv/$imageName
    docker tag docker.io/contiv/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# docker.io/ferest
images8=(
    etcd-initer:latest
)

for imageName in ${images8[@]} ; do
    docker pull docker.io/ferest/$imageName
    docker tag docker.io/ferest/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# docker.io/cilium
images9=(
    cilium:v1.3.0
)

for imageName in ${images9[@]} ; do
    docker pull docker.io/cilium/$imageName
    docker tag docker.io/cilium/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# docker.io/library
images10=(
    busybox:1.28.4
)

# docker.io/cloudnativelabs
images11=(
    kube-router:v0.2.5
)

for imageName in ${images11[@]} ; do
    docker pull docker.io/cloudnativelabs/$imageName
    docker tag docker.io/cloudnativelabs/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# docker.io/nfvpe
images12=(
    multus:v3.1.autoconf
)

for imageName in ${images12[@]} ; do
    docker pull docker.io/nfvpe/$imageName
    docker tag docker.io/nfvpe/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# docker.io
images13=(
    nginx:1.15
    haproxy:1.9
    busybox:latest
    busybox:1.29.2
    registry:2.6
)

for imageName in ${images13[@]} ; do
    docker pull docker.io/$imageName
    docker tag docker.io/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# docker.io/coredns
images14=(
    coredns:1.5.0
)

for imageName in ${images14[@]} ; do
    docker pull docker.io/coredns/$imageName
    docker tag docker.io/coredns/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# k8s.gcr.io
images15=(
    k8s-dns-node-cache:1.15.1
    cluster-proportional-autoscaler-amd64:1.4.0
    addon-resizer:1.8.3
    kube-apiserver:v1.14.3
    kube-controller-manager:v1.14.3
    kube-scheduler:v1.14.3
    kube-proxy:v1.14.3
    kube-apiserver-amd64:v1.14.3
    kube-controller-manager-amd64:v1.14.3
    kube-scheduler-amd64:v1.14.3
    kube-proxy-amd64:v1.14.3
    pause:3.1
    etcd:3.3.10
    coredns:1.3.1
)

for imageName in ${images15[@]} ; do
    docker pull k8s.gcr.io/$imageName
    docker tag k8s.gcr.io/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# docker.io/lachlanevenson
images16=(
    k8s-helm:v2.13.1
)

for imageName in ${images16[@]} ; do
    docker pull docker.io/lachlanevenson/$imageName
    docker tag docker.io/lachlanevenson/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done
    
# gcr.io/kubernetes-helm
images17=(
    tiller:v2.13.1
)

for imageName in ${images17[@]} ; do
    docker pull gcr.io/kubernetes-helm/$imageName
    docker tag gcr.io/kubernetes-helm/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# quay.io/external_storage
images18=(
    local-volume-provisioner:v2.1.0
    cephfs-provisioner:v2.1.0-k8s1.11
    rbd-provisioner:v2.1.1-k8s1.11
)

for imageName in ${images18[@]} ; do
    docker pull quay.io/external_storage/$imageName
    docker tag quay.io/external_storage/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# docker.io/rancher
images19=(
    local-path-provisioner:v0.0.2
)

for imageName in ${images19[@]} ; do
    docker pull docker.io/rancher/$imageName
    docker tag docker.io/rancher/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# quay.io/kubernetes-ingress-controller
images20=(
    nginx-ingress-controller:0.21.0
)

for imageName in ${images20[@]} ; do
    docker pull quay.io/kubernetes-ingress-controller/$imageName
    docker tag quay.io/kubernetes-ingress-controller/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done

# quay.io/jetstack
images21=(
    cert-manager-controller:v0.5.2
)

for imageName in ${images21[@]} ; do
    docker pull quay.io/jetstack/$imageName
    docker tag quay.io/jetstack/$imageName registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
    docker push registry.cn-hangzhou.aliyuncs.com/brucexu/$imageName
done
```

### 安装Kubespray
选择一台主机作为ansible-client机器，安装kubespray：
```bash
git clone https://github.com/kubernetes-incubator/kubespray.git
cd kubespray
git checkout v2.10.3
```

### 配置Kubespray
#### 主机配置:
```bash
cp -rf inventory/sample inventory/mycluster
```
#### 安装配置Kubespray需要包
```bash
sudo pip install -r requirements.txt
```
 
修改`inventory/mycluster/inventory.ini`如下:
```bash
[all]
ha-k8s-001 ansible_host=192.168.1.113  ip=192.168.1.113 etcd_member_name=etcd1
ha-k8s-002 ansible_host=192.168.1.114  ip=192.168.1.114 etcd_member_name=etcd2
ha-k8s-003 ansible_host=192.168.1.115  ip=192.168.1.115 etcd_member_name=etcd3

[kube-master]
ha-k8s-001
ha-k8s-002

[etcd]
ha-k8s-001
ha-k8s-002
ha-k8s-003

[kube-node]
ha-k8s-001
ha-k8s-002
ha-k8s-003

[k8s-cluster:children]
kube-master
kube-node
```

#### 修改二进制下载地址&镜像源
打开`roles/download/defaults/main.yml`，可以看到
```bash
# Download URLs
kubeadm_download_url: "https://storage.googleapis.com/kubernetes-release/release/{{ kubeadm_version }}/bin/linux/{{ image_arch }}/kubeadm"
hyperkube_download_url: "https://storage.googleapis.com/kubernetes-release/release/{{ kube_version }}/bin/linux/{{ image_arch }}/hyperkube"
etcd_download_url: "https://github.com/coreos/etcd/releases/download/{{ etcd_version }}/etcd-{{ etcd_version }}-linux-{{ image_arch }}.tar.gz"
cni_download_url: "https://github.com/containernetworking/plugins/releases/download/{{ cni_version }}/cni-plugins-linux-{{ image_arch }}-{{ cni_version }}.tgz"
calicoctl_download_url: "https://github.com/projectcalico/calicoctl/releases/download/{{ calico_ctl_version }}/calicoctl-linux-{{ image_arch }}"
```
部分地址国内不可达,可考虑通过VPS手动获取，上传到阿里云OSS，然后替换成OSS地址。

修改`inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml`，如下：
```bash
# Download URLs
kubeadm_download_url: "https://snp-assets.oss-cn-shanghai.aliyuncs.com/softws/kubespray_download/v2.10.3/kubeadm"
hyperkube_download_url: "https://snp-assets.oss-cn-shanghai.aliyuncs.com/softws/kubespray_download/v2.10.3/hyperkube"
etcd_download_url: "https://snp-assets.oss-cn-shanghai.aliyuncs.com/softws/kubespray_download/v2.10.3/etcd-v3.2.26-linux-amd64.tar.gz"
cni_download_url: "https://snp-assets.oss-cn-shanghai.aliyuncs.com/softws/kubespray_download/v2.10.3/cni-plugins-amd64-v0.6.0.tgz"
calicoctl_download_url: "https://snp-assets.oss-cn-shanghai.aliyuncs.com/softws/kubespray_download/v2.10.3/calicoctl-linux-amd64"

etcd_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/etcd"
flannel_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/flannel"
flannel_cni_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/flannel-cni"
calico_node_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/node"
calico_cni_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/cni"
calico_policy_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/kube-controllers"
calico_rr_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/routereflector"
calico_typha_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/typha"
pod_infra_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/pause-amd64"
install_socat_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/install-socat"
netcheck_agent_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/k8s-netchecker-agent"
netcheck_server_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/k8s-netchecker-server"
weave_kube_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/weave-kube"
weave_npc_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/weave-npc"
contiv_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/netplugin"
contiv_init_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/netplugin-init"
contiv_auth_proxy_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/auth_proxy"
contiv_etcd_init_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/etcd-initer"
contiv_ovs_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/ovs"
cilium_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/cilium"
cilium_init_image_repo: "docker.io/library/busybox"
kube_router_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/kube-router"
multus_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/multus"
nginx_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/nginx"

haproxy_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/haproxy"

coredns_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/coredns"

nodelocaldns_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/k8s-dns-node-cache"

dnsautoscaler_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/cluster-proportional-autoscaler-{{ image_arch }}"
test_image_repo: docker.io/busybox
busybox_image_repo: docker.io/busybox
helm_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/k8s-helm"
tiller_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/tiller"

registry_image_repo: "docker.io/registry"
registry_proxy_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/kube-registry-proxy"
metrics_server_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/metrics-server-amd64"
local_volume_provisioner_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/local-volume-provisioner"
cephfs_provisioner_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/cephfs-provisioner"
rbd_provisioner_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/rbd-provisioner"
local_path_provisioner_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/local-path-provisioner"
ingress_nginx_controller_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/nginx-ingress-controller"
cert_manager_controller_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/cert-manager-controller"
addon_resizer_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/addon-resizer"

dashboard_image_repo: "registry.cn-hangzhou.aliyuncs.com/brucexu/kubernetes-dashboard-amd64"


helm_stable_repo_url: "https://aliacs-app-catalog.oss-cn-hangzhou.aliyuncs.com/charts/"
```

#### 部署
使用ansible playbook部署kubespray
```bash
ansible-playbook -i inventory/mycluster/inventory.ini --become --become-user=root cluster.yml
```
 
> TIPS:
> kubespray调用kubeadm初始化master节点可能或比较漫长，打开`roles/kubernetes/master/tasks/kubeadm-setup.yml`可以看到:
```bash
- name: kubeadm | Initialize first master
  command: >-
    timeout -k 600s 600s
```
> 可以根据自己的需求修改timeout

等待大概20分钟左右，Kubernetes集群即可安装完成

#### 验证
```bash
kubectl get nodes
```
正常应该看到:
```bash
NAME         STATUS   ROLES    AGE   VERSION
ha-k8s-001   Ready    master   8m31s   v1.14.3
ha-k8s-002   Ready    master   7m26s   v1.14.3
ha-k8s-003   Ready    master   6m59s   v1.14.3
```
然后就可以快乐的享用了^_^

### 访问Kubernetes Dashboard
可以参考以下方案：
1. [https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/#accessing-the-dashboard-ui](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/#accessing-the-dashboard-ui)
2. [https://k8s-deploy.mzhpan.cn/09-2.dashboard%E6%8F%92%E4%BB%B6.html#%E8%AE%BF%E9%97%AE-dashboard](https://k8s-deploy.mzhpan.cn/09-2.dashboard%E6%8F%92%E4%BB%B6.html#%E8%AE%BF%E9%97%AE-dashboard)


> **参考:**
> 
> *[生产环境工具kubespray](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/)*
>
> *[Kubespray 快速开始](https://kubespray.io/#/?id=quick-start)*
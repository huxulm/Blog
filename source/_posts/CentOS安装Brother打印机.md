---
layout: post
title: CentOS 安装 Brother 打印机
date: 2019-04-25 13:15:54
tags: CentOS
---

### 进入下载页面
[https://support.brother.com/g/b/countrytop.aspx?c=cn&lang=zh](https://support.brother.com/g/b/countrytop.aspx?c=cn&lang=zh)

![Download Page](/images/04-25/Screenshot-from-2019-04-25-13-22-30.png)

### 下载驱动安装工具(Driver Install Tool)
 
```bash
cd ~/Downloads && \
wget https://download.brother.com/welcome/dlf006893/linux-brprinter-installer-2.2.1-1.gz
```
驱动安装工具说明:
 
|名称|功能|
|-|-|
|Driver Install Tool|该工具会安装LPR, CUPSwrapper驱动以及扫描器(scanner)驱动 (用于扫描模型).|
 
### 解压
```bash
gunzip -c ~/Downloads/linux-brprinter-installer*.gz > /tmp/linux-brprinter-installer
```
 
### 添加可执行权限
```bash
su -c "chmod +x linux-brprinter-installer"
```
 
### 安装打印机驱动(这里安装的是MFC-8450DN)
```bash
sudo ./linux-brprinter-installer
```
![安装](/images/04-25/Screenshot-from-2019-04-25-16-16-05.png)

### 提示`Will you specify the Device URI? [Y/n]时:
- USB连接选择`n`
- 网络共享连接浏览器打开: (http://localhost:631/printers/)[http://localhost:631/printers/]
  - 选择`Printer`
  - 选择`Modify Printer`
  - 输入sudo用户名密码
  - 选择`Protocal`继续

最后,前往`System Tools` > `Settings` > `Devices` > `Printers` 解锁后点击添加打印机.

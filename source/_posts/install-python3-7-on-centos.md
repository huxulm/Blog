---
layout: post
title: 在CentOS/RHEL 7/6 & Fedora 30-25上安装Python 3.7
date: 2019-06-21 16:59:20
tags:
    - CentOSx
---

### 安装必要包
Python安装需要GCC编译器
```bash
yum install gcc openssl-devel bzip2-devel libffi-devel
```

### 下载Python 3.7
```bash
wget https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tgz
```
解压
```bash
tar xzf Python-3.7.3.tgz
```

### 安装Python 3.7
```bash
./configure --enable-optimizations
make
make install
```

### 检查Python版本
```bash
python3.7 -V
```

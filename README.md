# SSMGR-Bash

##简介
一键部署ss-manager项目节点端以及主控端。

##特性
懒得写

##注意事项
1.必须有一个节点服务器才可以安装主控端服务器。

2.节点服务器内存最低要求为 256mb

3.请使用纯净系统安装，切勿用于生产环境
##安装
节点服务器：

    wget -N --no-check-certificate https://github.com/FunctionClub/SSMGR-Bash/raw/master/node.sh && bash node.sh

主控服务器：

    wget -N --no-check-certificate https://github.com/FunctionClub/SSMGR-Bash/raw/master/master.sh && bash master.sh
    
##感谢

https://github.com/shadowsocks/shadowsocks-manager
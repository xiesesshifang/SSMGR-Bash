#Check Root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }
#Check Root

#Check OS Start
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ]; then
  OS=CentOS
  [ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
  [ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
  [ -n "$(grep ' 5\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && CentOS_RHEL_version=5
elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ]; then
  OS=CentOS
  CentOS_RHEL_version=6
elif [ -n "$(grep bian /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Debian' ]; then
  OS=Debian
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Deepin /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Deepin' ]; then
  OS=Debian
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Ubuntu /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Ubuntu' -o -n "$(grep 'Linux Mint' /etc/issue)" ]; then
  OS=Ubuntu
  [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
  Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
  [ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && Ubuntu_version=16
else
  echo "${CFAILURE}Does not support this OS, Please contact the author! ${CEND}"
  kill -9 $$
fi

if [ $(getconf WORD_BIT) == 32 ] && [ $(getconf LONG_BIT) == 64 ]; then
  OS_BIT=64
else
  OS_BIT=32
fi
#Check OS End

#Disable SELinux Start
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
#Disable SELinux End

#Get IP Start
ipc=$(ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1)
if [[ "$IP" = "" ]]; then
    ipc=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
fi
#Get IP End

clear

#Read Node Information From User
echo "1.aes-256-cfb"
echo "2.aes-192-cfb"
echo ""
while :; do echo
  stty erase '^H' && read -p "请选择节点加密方式:" choosemethod
  if [[ "$choosemethod" =~ ^(-?|\+?)[0-9]+(\.?[0-9]+)?$ ]]
  then
     break
  else
     echo 'Input Error!'
  fi
done

if [[ $choosemethod == 1 ]];then
  method="aes-256-cfb"
fi

if [[ $choosemethod == 2 ]];then
  method="aes-192-cfb"
fi




stty erase '^H' && read -p "节点端口（默认：4001）:" serverport
[ -z "$serverport" ] && serverport=4001

stty erase '^H' && read -p "节点密码（默认：654321）:" apipasswd
[ -z "$apipasswd" ] && apipasswd=654321
confapipasswd="'${apipasswd}'"

#


#Install Required Packages Start
if [[ $OS == Ubuntu ]]; then
  apt-get -y update
  apt-get -y --no-install-recommends install gettext build-essential screen autoconf automake libtool openssl libssl-dev zlib1g-dev xmlto asciidoc libpcre3-dev libudns-dev libev-dev language-pack-zh-hans
fi


if [[ $OS == Debian ]]; then
  apt-get -y update
  apt-get -y --no-install-recommends install gettext build-essential screen autoconf automake libtool openssl libssl-dev zlib1g-dev xmlto asciidoc libpcre3-dev libudns-dev libev-dev
fi

if [[ $OS == CentOS ]]; then
  yum install -y gcc gettext-devel unzip autoconf automake make zlib-devel libtool xmlto asciidoc udns-devel libev-devel
  yum install -y pcre pcre-devel perl perl-devel cpio expat-devel openssl-devel mbedtls-devel screen
fi
#Install Required Packages End


#Install Nodejs Start
mkdir /usr/local/nodejs
if [ ${OS_BIT} == 32 ];then
  wget -N --no-check-certificate https://nodejs.org/dist/v6.9.1/node-v6.9.1-linux-x86.tar.gz
  tar -xf node-v6.9.1-linux-x86.tar.gz -C /usr/local/nodejs/
  rm -rf node-v6.9.1-linux-x86.tar.gz
  ln -s /usr/local/nodejs/node-v6.9.1-linux-x86/bin/node /usr/local/bin/node
  ln -s /usr/local/nodejs/node-v6.9.1-linux-x86/bin/npm /usr/local/bin/npm
fi

if [ ${OS_BIT} == 64 ];then
  wget -N --no-check-certificate https://nodejs.org/dist/v6.9.1/node-v6.9.1-linux-x64.tar.gz
  tar -xf node-v6.9.1-linux-x64.tar.gz -C /usr/local/nodejs/
  rm -rf node-v6.9.1-linux-x64.tar.gz
  ln -s /usr/local/nodejs/node-v6.9.1-linux-x64/bin/node /usr/local/bin/node
  ln -s /usr/local/nodejs/node-v6.9.1-linux-x64/bin/npm /usr/local/bin/npm
fi
#Install Nodejs End

#Install Lib Start
export LIBSODIUM_VER=1.0.11
export MBEDTLS_VER=2.4.0
wget --no-check-certificate https://github.com/jedisct1/libsodium/releases/download/1.0.11/libsodium-$LIBSODIUM_VER.tar.gz
tar xvf libsodium-$LIBSODIUM_VER.tar.gz && rm -rf libsodium-$LIBSODIUM_VER.tar.gz
pushd libsodium-$LIBSODIUM_VER
./configure --prefix=/usr && make
make install
popd
wget --no-check-certificate https://tls.mbed.org/download/mbedtls-$MBEDTLS_VER-gpl.tgz
tar xvf mbedtls-$MBEDTLS_VER-gpl.tgz && rm -rf mbedtls-$MBEDTLS_VER-gpl.tgz
pushd mbedtls-$MBEDTLS_VER
make SHARED=1 CFLAGS=-fPIC
make DESTDIR=/usr install
popd
ldconfig

#Install Lib End

#Install Shadowsocks-Libev Start
wget --no-check-certificate https://github.com/shadowsocks/shadowsocks-libev/releases/download/v3.0.3/shadowsocks-libev-3.0.3.tar.gz
tar -xf shadowsocks-libev-3.0.3.tar.gz && rm -rf shadowsocks-libev-3.0.3.tar.gz && cd shadowsocks-libev-3.0.3
./configure
make && make install
cd ../ && rm -rf shadowsocks-libev-3.0.3
#Install Shadowsocks-Libev End

npm i -g shadowsocks-manager
ln -s /usr/local/nodejs/node-v6.9.1-linux-x64/bin/ssmgr /usr/local/bin/ssmgr


#Setup ss-manager && ssmgr
screen -dmS ss-manager ss-manager -m $method -u --manager-address 127.0.0.1:4000
mkdir -p ~/.ssmgr/
cat << EOF > ~/.ssmgr/ss.yml
type: s
empty: false
shadowsocks:
  address: 127.0.0.1:4000
manager:
  address: 0.0.0.0:${serverport}
  password: ${confapipasswd}
db: 'ss.sqlite'
EOF

cd ~/.ssmgr
screen -dmS ssmgr ssmgr -c ss.yml
cd ..
#Setup End

#Disable iptables Start
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F
#Disable iptables End

clear
echo "节点配置成功！遇到问题请提交Issue反馈！"
echo ""
echo "节点加密方式：$method"
echo "节点服务器IP地址：${ipc}"
echo "节点端口：${serverport}"
echo "节点密码：${apipasswd}"

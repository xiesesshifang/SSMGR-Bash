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
stty erase '^H' && read -p "请输入一个节点服务器的IP地址:" nodeip

while :; do echo
	stty erase '^H' && read -p "请输入节点端口:" nodeport
	if [[ "$nodeport" =~ ^(-?|\+?)[0-9]+(\.?[0-9]+)?$ ]]
	then
	   break
	else
	   echo 'Input Error!'
	fi
done

stty erase '^H' && read -p "请输入节点的密码:" nodepasswd

stty erase '^H' && read -p "请输入SMTP发件地址:" smtpaddress

stty erase '^H' && read -p "请输入SMTP邮箱帐号:" smtpemail

stty erase '^H' && read -p "请输入SMTP邮箱密码:" smtppasswd

stty erase '^H' && read -p "是否现在配置TelegramBot (y/n):" ifbot

if [[ $ifbot == 'y' ]];then
	stty erase '^H' && read -p "请输入您的TelegramBot的Token:" bottoken
	ifbot="true"
else
	ifbot="false"
fi

stty erase '^H' && read -p "请输入本站点域名（不含http）:" site


#Adjust vars
confignodepasswd="'${nodepasswd}'"
configsmtpaddress="'${smtpaddress}'"
configsmtpmail="'${smtpemail}'"
configsmtppasswd="'${smtppasswd}'"
configsite="'${site}'"
configbottoken="'${bottoken}'"
#Adjust vars

#Install Required Packages Start
if [[ $OS == Ubuntu ]]; then
  apt-get -y update
  apt-get -y --no-install-recommends install wget curl screen 
fi


if [[ $OS == Debian ]]; then
  apt-get -y update
  apt-get -y --no-install-recommends install wget curl screen
fi

if [[ $OS == CentOS ]]; then
  yum install -y wget curl screen
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

#Setup ssmgr Start
npm i -g shadowsocks-manager
ln -s /usr/local/nodejs/node-v6.9.1-linux-x64/bin/ssmgr /usr/local/bin/ssmgr
mkdir -p ~/.ssmgr/
cat << EOF > ~/.ssmgr/webgui.yml
type: m
empty: false

manager:
  address: ${nodeip}:${nodeport}
  password: ${confignodepasswd}
  # 这部分的端口和密码需要跟上一步 manager 参数里的保持一致
plugins:
  flowSaver:
    use: true
  user:
    use: true
  account:
    use: true
    pay:
      hour:
        price: 0.03
        flow: 500000000
      day:
        price: 0.5
        flow: 7000000000
      week:
        price: 3
        flow: 50000000000
      month:
        price: 10
        flow: 200000000000
      season:
        price: 30
        flow: 200000000000
      year:
        price: 120
        flow: 200000000000
  email:
    use: true
    username: ${configsmtpmail}
    password: ${configsmtppasswd}
    host: ${configsmtpaddress}
    # 这部分的邮箱和密码是用于发送注册验证邮件，重置密码邮件使用的
  webgui:
    use: true
    host: '0.0.0.0'
    port: '80'
    site: ${configsite}
    gcmSenderId: '456102641793'
    gcmAPIKey: 'AAAAGzzdqrE:XXXXXXXXXXXXXX'
  telegram:
    token: ${configbottoken}
    use: ${ifbot}
  alipay:
    use: true
    appid: 2015012108272442
    notifyUrl: ''
    merchantPrivateKey: 'xxxxxxxxxxxx'
    alipayPublicKey: 'xxxxxxxxxxx'
    gatewayUrl: 'https://openapi.alipay.com/gateway.do'

db: 'webgui.sqlite'
EOF

#Setup ssmgr End
cd ~/.ssmgr
screen -dmS webgui ssmgr -c webgui.yml
cd ..

echo "服务端配置完成！"
echo "您可以访问 http://${ipc}进行查看！"
echo "价格配置，支付宝当面付接口可在 /root/.ssmgr/webgui.yml 文件中进行配置。"

#! /bin/bash
# $author: twfcc@twitter
# $PROG: install_sslproxy.sh
# $Usage: $0 {-n|-s} 
# description: install HTTPS/SSL proxy on [NAT IPv4 Share|Dedicated IPv4] VPS(OpenVZ)
# Public Domain use as your own risk!
# Works on Debian 7 and Ubuntu 14.04 only

trap cleanup INT

cleanup(){
	mv -f /etc/tinyproxy.conf.bak /etc/tinyproxy.conf 2> /dev/null
	mv -f /etc/default/stunnel4.bak /etc/default/stunnel4 2> /dev/null
	apt-get remove tinyproxy -y
	apt-get remove stunnel -y
	rm -f "$HOME/publickey.pem" 2> /dev/null
	rm -f "$HOME/privatekey.pem" 2> /dev/null
	rm -f "$HOME/publickey.crt" 2> /dev/null
	rm -f /etc/stunnel/stunnel.conf 2> /dev/null
	exit 1
}

if [ $UID -ne 0 ] ; then
	echo "You must be root to execute this script." >&2
	exit 1
fi

[ $(pwd) != "/root" ] && cd "$HOME"

case "$1" in 
	-n) flag=0 ;;
	-s) flag=1 ;;
	 *) echo "Usage: ${0##*/} {-n|-s}" >&2 ;
	    echo "-n : install HTTPS/SSL proxy on NAT IPv4 Share VPS." >&2 ;
	    echo "-s : install HTTPS/SSL proxy on Dedicated IPv4 VPS." >&2 ;
	    exit 1
            ;;
esac

tinyproxy_install(){
	local cfg 
	apt-get install tinyproxy -y
	[ $? -eq 0 ] && cd "/etc" || {
		echo "Install tinyproxy failed." >&2 ;
		exit 1 ;
}
	cfg="tinyproxy.conf"
	[ -f "$cfg" ] && mv -f "$cfg" "${cfg}.bak" 2> /dev/null
	cat >"$cfg"<<EOF
User nobody
Group nogroup
Port 3128
Listen 127.0.0.1
Timeout 600
DefaultErrorFile "/usr/share/tinyproxy/default.html"
StatFile "/usr/share/tinyproxy/stats.html"
Logfile "/var/log/tinyproxy/tinyproxy.log"
LogLevel Connect
PidFile "/var/run/tinyproxy/tinyproxy.pid"
MaxClients 100
MinSpareServers 5
MaxSpareServers 20
StartServers 10
MaxRequestsPerChild 0
Allow 127.0.0.1
ViaProxyName "tinyproxy"
ConnectPort 443
ConnectPort 563

EOF

service tinyproxy restart
cd "$HOME"
}

gen_self_cert(){
	openssl genrsa -out privatekey.pem 2048
	openssl req -new -x509 -key privatekey.pem -subj \
	"/C=CN/ST=MyTunnel/L=Mytunnel/O=$myip/CN=$myip" \
	-out publickey.pem -days 1095
}

stunnel_install(){
	apt-get install stunnel4 -y
	gen_self_cert
	[ $? -eq 0 ] && {
		cat privatekey.pem publickey.pem > /etc/stunnel/stunnel.pem
		cat publickey.pem > publickey.crt
}

	cat >stunnel.conf<<EOF
client = no
debug = 7
output = /var/log/stunnel4/stunnel.log
[tinyproxy]
accept = $port
connect = 127.0.0.1:3128
cert = /etc/stunnel/stunnel.pem

EOF

	mv -f stunnel.conf /etc/stunnel/
	cp -f /etc/default/stunnel4 /etc/default/stunnel4.bak
	sed -i 's/^ENABLED=0$/ENABLED=1/' /etc/default/stunnel4 
	service stunnel4 restart
}

myip=$(wget -qO - v4.ifconfig.co)

if [ $flag -eq 0 ] ; then
	internal_ip=$(ifconfig venet0:0 \
		| awk -F: '$2 ~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/{print $2}' \
		| cut -d" " -f1) 
	port=${internal_ip##*.}20 
else
	pick=($(for i in {29901..29999} ;do echo $i ;done)) 
	count=${#pick[@]} 
	port=${pick[$((RANDOM%count-1))]}  
fi

apt-get update && apt-get upgrade -y
apt-get install openssl libssl-dev -y
tinyproxy_install
stunnel_install

if netstat -nlp | grep -iq 'tinyproxy' && netstat -nlp | grep -iq 'stunnel4'
	then
		echo "HTTPS/SSL Proxy is running."
		echo "Copy publickey.crt and import to browser."
		echo ""
		echo "Public IP: $myip"
		echo "Port: $port"
		echo ""
		echo "Enjoy."
	else
		echo "Install HTTPS/SSL proxy failed." >&2
		cleanup
fi
exit 0

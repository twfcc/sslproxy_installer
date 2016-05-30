#! /bin/bash
# $author: twfcc@twitter
# $PROG: s3proxy.sh
# $description: install HTTPS/SSL proxy on [NAT IPv4 Share|Dedicated IPv4] VPS(OpenVZ)
#		Stunnel4 + 3proxy with user authentication
# $Usage: $0 {-n|-s} 
#	  -n : NAT IPv4 Share VPS	-s : Dedicated IPv4 VPS
# Works on Debian 7/8 and Ubuntu 14.04/15.04 
# Public domain use as your own risk!

trap cleanup INT

cleanup(){
	kill $(ps aux | grep 3proxy | grep -v grep | awk '{print $2}') 2> /dev/null
	rm -rf "$HOME/3proxy" 
	rm -rf /usr/local/etc/3proxy/ 2> /dev/null
	update-rc.d -f 3proxyinit remove 2> /dev/null
	rm -f /etc/init.d/3proxyinit 2> /dev/null 
	mv -f /etc/default/stunnel4.bak /etc/default/stunnel4 2> /dev/null
	rm -f "$HOME/publickey.pem" 2> /dev/null
	rm -f "$HOME/privatekey.pem" 2> /dev/null
	rm -f "$HOME/publickey.crt" 2> /dev/null
	rm -f /etc/stunnel/stunnel.conf 2> /dev/null
	apt-get purge stunnel4 -y
	exit 1
}

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export LANGUAGE=C
export LC_ALL=C

[ $UID -ne 0 ] && {
	echo "This script must be executed by root." >&2
	exit 1
}

[ $(pwd) != "/root" ] && cd "$HOME"

myip=$(wget -qO - v4.ifconfig.co)

3proxy_install(){
	git clone https://github.com/z3APA3A/3proxy.git ;
	[ $? -eq 0 ] || {
		echo "Clone 3proxy.git failed.exiting..." >&2 ;
		exit 1 ;
	}
	cd 3proxy/ || {
		echo "Cannot change to 3proxy directory." >&2 ;
		exit 1 ;
	}
	make -f Makefile.Linux ;
	[ $? -eq 0 ] && cd src/ ;
	mkdir -p /usr/local/etc/3proxy/bin/ ;
	install 3proxy /usr/local/etc/3proxy/bin/3proxy ;
	install mycrypt /usr/local/etc/3proxy/bin/mycrypt ;
	touch /usr/local/etc/3proxy/3proxy.cfg ;
	mkdir -p /usr/local/etc/3proxy/log/ ;
	chown -R root:root /usr/local/etc/3proxy/ ;
	chown -R 65535 /usr/local/etc/3proxy/log/ ;
	touch /usr/local/etc/3proxy/3proxy.pid ;
	chown 65535 /usr/local/etc/3proxy/3proxy.pid ;
	local cfg
	cfg="/usr/local/etc/3proxy/3proxy.cfg"
	cat >"$cfg"<<EOF
nscache 65536
nserver 8.8.8.8
nserver 8.8.4.4
timeouts 1 5 30 60 180 1800 15 60
daemon
pidfile 3proxy.pid
config 3proxy.cfg
monitor 3proxy.cfg
log log/3proxy.log D
logformat "L%d-%m-%Y %H:%M:%S %z %N.%p %E %U %C:%c %R:%r %O %I %h %T"
rotate 30
allow * * * 80-88,8080-8088 
allow * * * 443,8443
allow * * * 5222,5223,5228
allow * * * 465,587,995
proxy -i127.0.0.1 -a -p3128
flush
chroot /usr/local/etc/3proxy/
setgid 65535
setuid 65535
auth strong
users ${username}:CL:${pass}

EOF

	cd /etc/init.d/ || {
		echo "Cannot change to /etc/init.d/ directory." >&2 ;
		exit 1 ;
	}
	cat >3proxyinit<<EOF
#! /bin/sh
#
### BEGIN INIT INFO
# Provides: 3Proxy
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Initialize 3proxy server
# Description: starts 3proxy
### END INIT INFO

cd /usr/local/etc/3proxy/
case "\$1" in
	start)  echo "Starting 3Proxy" ;
		/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg
		 ;;
	 stop)  echo "Stopping 3Proxy" ;
		kill \`ps aux | grep 3proxy | grep -v grep | awk '{print \$2}'\`
		;;
	    *)  echo Usage: \\\$0 "{start|stop}" ;
		exit 1 ;
		;;
esac
exit 0

EOF

	if [ -e 3proxyinit ] ; then
		bash -n 3proxyinit > /dev/null 2>&1 ;
		[ $? -eq 0 ] && { 
			chmod +x 3proxyinit ;
			update-rc.d 3proxyinit defaults ;
		} || {
			echo "3proxyinit script is something wrong." >&2 ;
			exit 1 ;
		}
		cd "$HOME" ;
		/etc/init.d/3proxyinit start ;
	else
		echo "3proxyinit script is not exist." >&2 ;
		exit 1
	fi
}

username_gen(){
	local uletter digit ulength dlength i username pick 
	uletter="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	digit="123456789"
	ulength=${#uletter}
	dlength=${#digit}
	for ((i=1 ; i<=2 ; i++)) ; do
		pick=${uletter:$((RANDOM%ulength-1)):1}${digit:$((RANDOM%dlength-1)):1}
		username="$username$pick"
	done
	echo "$username"
}

password_gen(){
        local matrix pw count pick i howmany
	howmany=10
        matrix="123456789aAbBcCdDeEfFgGhHiIjJkKLmMnNpPqQrRsStTuUvVwWxXyYzZ"
        count="${#matrix}"
        for ((i=1 ; i<=howmany ;i++)) ; do
                pick=${matrix:$((RANDOM%count-1)):1}
                pw="$pw$pick"
        done
        echo "$pw"
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
[3proxy]
accept = $port
connect = 127.0.0.1:3128
cert = /etc/stunnel/stunnel.pem

EOF

	mv -f stunnel.conf /etc/stunnel/
	cp -f /etc/default/stunnel4 /etc/default/stunnel4.bak
	sed -i 's/^ENABLED=0$/ENABLED=1/' /etc/default/stunnel4 
	service stunnel4 restart
}

username=$(username_gen)
pass=$(password_gen)

case "$1" in 
	-n) flag=0 ;;
	-s) flag=1 ;;
	 *) echo "Usage: ${0##*/} {-n|-s}" >&2 ;
	    echo "-n : install HTTPS/SSL proxy on NAT IPv4 Share VPS." >&2 ;
	    echo "-s : install HTTPS/SSL proxy on Dedicated IPv4 VPS." >&2 ;
	    exit 1
            ;;
esac

if [ $flag -eq 0 ] ; then
	internal_ip=$(ifconfig venet0:0 \
		| awk -F: '$2 ~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/{print $2}' \
		| cut -d" " -f1) 
	port=${internal_ip##*.}20 
else
	pick=($(for i in {18801..18999} ;do echo $i ;done)) 
	count=${#pick[@]} 
	port=${pick[$((RANDOM%count-1))]}  
fi

apt-get update && apt-get upgrade -y
apt-get install openssl git build-essential libssl-dev -y
3proxy_install
stunnel_install

if netstat -nlp | grep -iq '3proxy' && netstat -nlp | grep -iq 'stunnel4'
	then
		echo "HTTPS/SSL Proxy is running."
		echo "Copy publickey.crt and import to browser."
		echo ""
		echo "Public IP: $myip"
		echo "Port: $port"
		echo "User: $username"
		echo "Password: $pass"
		echo ""
		echo "Enjoy."
	else
		echo "Install HTTPS/SSL proxy failed." >&2
		cleanup
fi
exit 0

#! /bin/bash
# $author: twfcc@twitter
# $description: uninstall compontents installed by [stiny.sh|s3proxy.sh]
# $usage: $0
# Public domain use as your own risk

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[ $(whoami) != "root" ] && {
	echo "Execute this script must be root." >&2 
	exit 1
}

[ $(pwd) != "/root" ] && cd $HOME

s3proxy_remove(){
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
}

stiny_remove(){
	mv -f /etc/tinyproxy.conf.bak /etc/tinyproxy.conf 2> /dev/null
	mv -f /etc/default/stunnel4.bak /etc/default/stunnel4 2> /dev/null
	apt-get purge tinyproxy -y
	apt-get purge stunnel -y
	rm -f "$HOME/publickey.pem" 2> /dev/null
	rm -f "$HOME/privatekey.pem" 2> /dev/null
	rm -f "$HOME/publickey.crt" 2> /dev/null
	rm -f /etc/stunnel/stunnel.conf 2> /dev/null
}

printf '%b' '\033[31mUninstall HTTPS/SSL proxy\033[39m'

if which tinyproxy > /dev/null 2>&1 
	then
		stiny_remove > /dev/null 2>&1
	else
		s3proxy_remove > /dev/null 2>&1
fi

echo -n "." ; sleep 1 ; echo -n " . " ; sleep 1
printf '%b\n' '\033[32mDone.\033[39m'
exit 0

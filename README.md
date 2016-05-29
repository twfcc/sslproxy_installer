# sslproxy_installer
HTTPS/SSL Proxy  bash install script

說明

stiny.sh是bash shell腳本，在[NAT IPv4 Share|Dedicated IPv4] VPS(OpenVZ)安裝HTTPS/SSL代理

安裝腳本可在Debian 7或Ubuntu 14.04使用

s3proxy.sh是bash shell腳本，在[NAT IPv4 Share|Dedicated IPv4] VPS(OpenVZ)安裝HTTPS/SSL代理

可在Ubuntu 14.04/15.04或Debian 7/8使用

只須選擇一個合適的腳本安裝服務器


使用方法

以root登錄VPS，執行以下命令:

wget --no-check-certificate https://raw.githubusercontent.com/twfcc/sslproxy_installer/master/stiny.sh

chmod +x stiny.sh

根據你的VPS類型，如果是NAT Share IPv4 VPS,執行:

./stiny.sh -n

獨立IPv4的VPS，執行:

./stiny.sh -s

如果以s3proxy.sh腳本安裝服務器

wget --no-check-certificate https://raw.githubusercontent.com/twfcc/sslproxy_installer/master/s3proxy.sh

chmod +x s3proxy.sh

根據你的VPS類型，輸入

./s3proxy.sh -n

或

./s3proxy.sh -s



Explanation

stiny.sh is a bash shell script for installing HTTPS/SSL proxy on [NAT IPv4 Share|Dedicated IPv4] VPS(OpenVZ)

Works on Debian 7 or Ubuntu 14.04.

s3proxy.sh is a bash shell script for installing HTTPS/SSL proxy on [NAT IPv4 Share|Dedicated IPv4] VPS

Works on Debian 7/8 or Ubuntu 14.04/15.04

Select the one script only which is suitable for your VPS installing proxy server.


Usage

Login your VPS with user 'root' via ssh client and follow steps as below.

wget --no-check-certificate https://raw.githubusercontent.com/twfcc/sslproxy_installer/master/stiny.sh

chmod +x stiny.sh

According to your VPS type, NAT Share IPv4 VPS input:

./stiny.sh -n

For Dedicated IPv4 VPS, input:

./stiny.sh -s

If you select s3proxy.sh to install HTTPS/SSL proxy server, inpu

wget --no-check-certificate https://raw.githubusercontent.com/twfcc/sslproxy_installer/master/s3proxy.sh

chmod +x s3proxy.sh

Accroding to Your VPS type, input:

./s3proxy.sh -n

or

./s3proxy.sh -s


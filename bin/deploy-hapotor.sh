#!/bin/bash

NUMBER_OF_IPS=$1

if [[ $NUMBER_OF_IPS -lt 1 ]]; then
	echo "Usage: $0 NUMBER_OF_IPS"
	exit 1;
fi

# Anonymous proxy services
ls /etc/init/|grep tor-10|cut -f1 -d.|xargs -I {} sudo service {} stop
ls /etc/init/|grep polipo-20|cut -f1 -d.|xargs -I {} sudo service {} stop

# Anonymous proxy - Remove files
find /etc/init/ -name "polipo-20*"|xargs sudo rm -f
find /etc/init/ -name "tor-10*"|xargs sudo rm -f

# Anonymous proxy - Generate files
for i in `seq -f %03g 1 $NUMBER_OF_IPS`; do
	sudo tee /etc/init/tor-10$i.conf > /dev/null <<-EOF
		description "Tor - $i"
		version "1.0"
		author "Corentin Merot"

		env PATH=/bin:/usr/bin:/usr/local/bin

		respawn
		start on runlevel [23]

		exec /usr/sbin/tor --SocksPort 10$i --NewCircuitPeriod 120 --DataDirectory /var/lib/tor/10$i
	EOF

	sudo tee /etc/init/polipo-20$i.conf > /dev/null <<-EOF
		description "Polipo http to socks proxy for Tor - $i"
		version "1.0"
		author "Corentin Merot"

		env PATH=/bin:/usr/bin:/usr/local/bin

		respawn
		start on runlevel [23]

		exec polipo proxyPort=20$i socksParentProxy=127.0.0.1:10$i socksProxyType=socks5 diskCacheRoot='' disableLocalInterface=true allowedClients=127.0.0.1 localDocumentRoot='' disableConfiguration=true dnsUseGethostbyname='yes' logSyslog=true disableVia=true allowedPorts='1-65535' tunnelAllowedPorts='1-65535'
	EOF
done

# Anonymous proxy - Start services
ls /etc/init/|grep tor-10|cut -f1 -d.|xargs -I {} sudo service {} start
ls /etc/init/|grep polipo-20|cut -f1 -d.|xargs -I {} sudo service {} start

# Polipo-cache service
sudo service polipo-5567 stop
sudo rm -f /etc/init/polipo-5567.conf
sudo tee /etc/init/polipo-5567.conf > /dev/null <<-EOF
	description "Polipo for caching"
	version "1.0"
	author "Corentin Merot"

	env PATH=/bin:/usr/bin:/usr/local/bin

	respawn
	start on runlevel [23]

	exec polipo parentProxy=127.0.0.1:5566 proxyPort=5567
EOF
sudo service polipo-5567 start

# Haproxy config
sudo tee /usr/local/etc/haproxy.cfg > /dev/null <<-EOF
	global
	  maxconn 1024
	  pidfile /var/run/haproxy.pid

	defaults
	  mode http
	  maxconn 1024
	  option  httplog
	  option  dontlognull
	  retries 3
	  timeout connect 5s
	  timeout client 60s
	  timeout server 60s

	frontend rotating_proxies
	  bind *:5566
	  default_backend tor
	  option http_proxy

	backend tor
	  option http_proxy
	  balance leastconn # http://cbonte.github.io/haproxy-dconv/configuration-1.5.html#balance
EOF
for i in `seq -f %03g 1 $NUMBER_OF_IPS`; do
	sudo tee -a /usr/local/etc/haproxy.cfg > /dev/null <<-EOF
	  server polipo20$i 127.0.0.1:20$i
	EOF
done

# Haproxy service
sudo service haproxy-5566 stop
sudo rm -f /etc/init/haproxy-5566.conf
sudo tee /etc/init/haproxy-5566.conf > /dev/null <<-EOF
	description "Haproxy leastconn balancer"
	version "1.0"
	author "Corentin Merot"

	env PATH=/bin:/usr/bin:/usr/local/bin

	respawn
	start on runlevel [23]

	exec /usr/sbin/haproxy -f /usr/local/etc/haproxy.cfg
EOF
sudo service haproxy-5566 start

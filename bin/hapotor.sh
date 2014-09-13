#!/bin/bash
# Wrapper for upstart
ls /etc/init/|grep tor-10|cut -f1 -d.|xargs -I {} sudo service {} $1
ls /etc/init/|grep polipo-20|cut -f1 -d.|xargs -I {} sudo service {} $1
sudo service haproxy-5566 $1
sudo service polipo-5567 $1

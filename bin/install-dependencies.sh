#!/bin/bash

set -e

## Install tor - https://www.torproject.org/docs/debian.html.en#ubuntu

gpg --keyserver keys.gnupg.net --recv 886DDD89
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -
echo 'deb http://deb.torproject.org/torproject.org trusty main' | sudo tee /etc/apt/sources.list.d/tor.list
sudo apt-get update
sudo apt-get install -y deb.torproject.org-keyring tor

# disable the tor service
sudo service tor stop
sudo update-rc.d tor disable

## Install polipo

# disable the polipo service
sudo apt-get install -y polipo
sudo update-rc.d polipo disable

## Instal haproxy

## haproxy is disabled by default in /etc/init.d/haproxy
## nevertheless we disable the service aswell
sudo apt-get install -y haproxy
sudo update-rc.d haproxy disable

# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# This is the inline shell script that will be executed to install the machine
$install = <<SCRIPT
apt-get update
/vagrant/bin/install-dependencies.sh
cp /vagrant/bin/deploy-hapotor.sh /usr/local/bin/deploy-hapotor
cp /vagrant/bin/hapotor.sh /usr/local/bin/hapotor
deploy-hapotor 5
hapotor status
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.provision "shell", inline: $install
  config.vm.network "forwarded_port", host: 5566, guest: 5566, auto_correct: true
  config.vm.network "forwarded_port", host: 5567, guest: 5567, auto_correct: true
end

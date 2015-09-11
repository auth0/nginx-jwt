# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  # copy over handy configuration from host, like Git settings and SSH key
  config.vm.provision "file", source: "~/.gitconfig", destination: ".gitconfig"
  config.vm.provision "file", source: "~/.ssh/id_rsa", destination: ".ssh/id_rsa"

  # run provisioning script
  config.vm.provision :shell, :path => "provision-vagrant.sh"
end

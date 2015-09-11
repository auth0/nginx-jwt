#!/usr/bin/env bash

if [ -e "/etc/vagrant-provisioned" ];
then
    echo "Vagrant provisioning already completed. Skipping..."
    exit 0
else
    echo "Starting Vagrant provisioning process..."
fi

host='nginx-jwt'
# Change the hostname so we can easily identify what environment we're on:
echo $host > /etc/hostname
# Update /etc/hosts to match new hostname to avoid "Unable to resolve hostname" issue:
echo '127.0.0.1 $host' >> /etc/hosts
# Use hostname command so that the new hostname takes effect immediately without a restart:
hostname $host

# Install core components
apt-get update
apt-get install -y make g++ curl git vim nfs-common portmap build-essential libssl-dev

# Install Node.js
curl --silent --location https://deb.nodesource.com/setup_0.12 | sudo bash -
apt-get install --yes nodejs

# Install Docker
curl -sSL https://get.docker.com/ubuntu | sh

# Vim settings:
echo 'syntax on' > /home/vagrant/.vimrc

touch /etc/vagrant-provisioned

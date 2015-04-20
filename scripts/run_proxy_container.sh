#!/bin/sh

set -o pipefail
set -e

script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
. $script_dir/common.sh

proxy_name=$1
proxy_dir=$proxy_base_dir/$proxy_name

# make sure existing image/container is stopped/deleted
sh $script_dir/stop_proxy_container.sh $proxy_name

echo "${cyan}Building container and image for the '$proxy_name' proxy (Nginx) host...${no_color}"

echo "${blue}Deploying Lua scripts and depedencies${no_color}"
rm -rf $proxy_dir/nginx/lua
mkdir -p $proxy_dir/nginx/lua
cp $root_dir/nginx-jwt.lua $proxy_dir/nginx/lua
cp -r lib/ $proxy_dir/nginx/lua

echo "${blue}Building the new image${no_color}"
docker build -t="proxy-$proxy_name-image" --force-rm $proxy_dir

host_port="$(cat hosts/proxy/$proxy_name/host_port)"
echo "${blue}Staring new container, binding it to Docker host port $host_port${no_color}"
docker run --name "proxy-$proxy_name" -d -p $host_port:80 --link backend:backend "proxy-$proxy_name-image"

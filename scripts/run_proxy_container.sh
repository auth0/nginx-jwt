#!/bin/bash

set -o pipefail
set -e

script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
. $script_dir/common.sh

proxy_name=$1
proxy_dir=$proxy_base_dir/$proxy_name

# make sure existing image/container is stopped/deleted
$script_dir/stop_proxy_container.sh $proxy_name

echo -e "${cyan}Building container and image for the '$proxy_name' proxy (Nginx) host...${no_color}"

echo -e "${blue}Deploying Lua scripts and depedencies${no_color}"
rm -rf $proxy_dir/nginx/lua
mkdir -p $proxy_dir/nginx/lua
cp $root_dir/nginx-jwt.lua $proxy_dir/nginx/lua
cp -r lib/* $proxy_dir/nginx/lua

echo -e "${blue}Building the new image${no_color}"
docker build -t="proxy-$proxy_name-image" --force-rm $proxy_dir
docker run --name "proxy-$proxy_name" -d -p 80:80 --link backend:backend "proxy-$proxy_name-image"

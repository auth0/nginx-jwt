#!/bin/bash

set -o pipefail
set -e

script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
. $script_dir/common.sh

proxy_name=$1
proxy_dir=$proxy_base_dir/$proxy_name

echo -e "${cyan}Stopping the '$proxy_name' container and removing the image${no_color}"
docker rm -f "proxy-$proxy_name" &>/dev/null || true
docker rmi -f "proxy-$proxy_name-image" &>/dev/null || true

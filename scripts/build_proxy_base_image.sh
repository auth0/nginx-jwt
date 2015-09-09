#!/bin/bash

set -o pipefail
set -e

script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
. $script_dir/common.sh

echo -e "${cyan}Building base proxy image, if necessary...${NC}"
image_exists=$(docker images | grep "proxy-base-image") || true
if [ -z "$image_exists" ]; then
    echo -e "${blue}Building image${no_color}"
    docker build -t="proxy-base-image" --force-rm $proxy_base_dir
else
    echo -e "${blue}Base image already exists${no_color}"
fi

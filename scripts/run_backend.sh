#!/bin/bash

set -o pipefail
set -e

script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
. $script_dir/common.sh

# make sure existing image/container is stopped/deleted
$script_dir/stop_backend.sh

echo -e "${cyan}Building backend image...${no_color}"
docker build -t="backend-image" --force-rm $hosts_base_dir/backend
echo -e "${cyan}Starting backend container...${no_color}"
docker run --name backend -d backend-image

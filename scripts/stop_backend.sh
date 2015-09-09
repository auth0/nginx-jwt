#!/bin/bash

set -o pipefail
set -e


script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
. $script_dir/common.sh

echo -e "${cyan}Stopping the backend container and removing its image...${no_color}"
docker rm -f backend &>/dev/null || true
docker rmi -f backend-image &>/dev/null || true

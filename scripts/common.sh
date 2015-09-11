#!/bin/bash

set -o pipefail
set -e

script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
root_dir=$script_dir/..
hosts_base_dir=$root_dir/hosts
proxy_base_dir=$hosts_base_dir/proxy

cyan='\033[0;36m'
blue='\033[0;34m'
no_color='\033[0m'

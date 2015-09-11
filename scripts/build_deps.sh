#!/bin/bash

set -o pipefail
set -e

script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
. $script_dir/common.sh

echo -e "${cyan}Fetching Lua depedencies...${no_color}"
load_dependency () {
    local target="$1"
    local user="$2"
    local repo="$3"
    local commit="$4"
    local sha1="$5"

    local expected_sha1_response="SHA1($target)= $sha1"
    local actual_sha1_response=$(openssl sha1 $target)

    if [ -e "$target" ] && [ "$expected_sha1_response" == "$actual_sha1_response" ]; then
        echo -e "Dependency $target (with SHA-1 digest $sha1) already downloaded."
    else
        curl https://codeload.github.com/$user/$repo/tar.gz/$commit | tar -xz --strip 1 $repo-$commit/lib
    fi
}

load_dependency "lib/resty/jwt.lua" "SkyLothar" "lua-resty-jwt" "b7976481061239ae2027e02be552b900bf25321c" "3fbc737d2a1defcdf372cab5f854182afbcede6e"
load_dependency "lib/resty/hmac.lua" "jkeys089" "lua-resty-hmac" "67bff3fd6b7ce4f898b4c3deec7a1f6050ff9fc9" "44dffa232bdf20e9cf13fb37c23df089e4ae1ee2"
load_dependency "lib/basexx.lua" "aiq" "basexx" "514f46ceb9a8a867135856abf60aaacfd921d9b9" "da8efedf0d96a79a041eddfe45a6438ea4edf58b"

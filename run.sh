#!/bin/sh

cyan='\033[0;36m'
NC='\033[0m' # No Color

# get boot2docker host ip
HOST_IP=$(boot2docker ip)

echo "${cyan}Stopping the backend container and removing its image...${NC}"
docker rm -f backend &>/dev/null
docker rmi -f backend-image &>/dev/null
echo "${cyan}Building a new backend image...${NC}"
docker build -t="backend-image" --force-rm hosts/backend
echo "${cyan}Starting a new backend image...${NC}"
docker run --name backend -d -p 5000:5000 backend-image

#TODO: rename 'normal-secret' proxy image to 'default'
#TODO: create 2 more images/containers for 'configuration error scenarios':
#      - config-claim_specs-not-table
#      - config-unsupported-claim-spec-type
#TODO: refactor bash code to dynamically perform below operations on all hosts/proxy subdirectories

echo "${cyan}Fetching Lua depedencies...${NC}"
function load_dependency {
    local TARGET="$1"
    local USER="$2"
    local REPO="$3"
    local COMMIT="$4"

    if [ -e "$TARGET" ]; then
        echo "Dependency $TARGET already downloaded."
    else
        curl https://codeload.github.com/$USER/$REPO/tar.gz/$COMMIT | tar -xz --strip 1 $REPO-$COMMIT/lib
    fi
}

load_dependency "lib/resty/jwt.lua" "SkyLothar" "lua-resty-jwt" "586a507f9e57555bdd7a7bc152303c91b4a04527"
load_dependency "lib/resty/hmac.lua" "jkeys089" "lua-resty-hmac" "67bff3fd6b7ce4f898b4c3deec7a1f6050ff9fc9"
load_dependency "lib/basexx.lua" "aiq" "basexx" "c91cf5438385d9f84f53d3ef27f855c52ec2ed76"

echo "${cyan}Prepping files for the proxy (Nginx) container...${NC}"
rm -rf hosts/proxy/normal-secret/nginx/lua
rm -rf hosts/proxy/base64-secret/nginx/lua
mkdir -p hosts/proxy/normal-secret/nginx/lua
mkdir -p hosts/proxy/base64-secret/nginx/lua
cp nginx-jwt.lua hosts/proxy/normal-secret/nginx/lua
cp nginx-jwt.lua hosts/proxy/base64-secret/nginx/lua
cp -r lib/resty hosts/proxy/normal-secret/nginx/lua
cp -r lib/resty hosts/proxy/base64-secret/nginx/lua
cp -r lib/basexx.lua hosts/proxy/normal-secret/nginx/lua
cp -r lib/basexx.lua hosts/proxy/base64-secret/nginx/lua

echo "${cyan}Stopping the proxy (Nginx) containers and removing their images...${NC}"
docker rm -f proxy &>/dev/null
docker rm -f proxy-base64-secret &>/dev/null
docker rmi -f proxy-image &>/dev/null
docker rmi -f proxy-base64-secret-image &>/dev/null
echo "${cyan}Building new proxy images...${NC}"
docker build -t="proxy-image" --force-rm hosts/proxy/normal-secret
docker build -t="proxy-base64-secret-image" --force-rm hosts/proxy/base64-secret
echo "${cyan}Starting new proxy container...${NC}"
docker run --name proxy -d -p 80:80 --add-host "backend_host:$HOST_IP" proxy-image
docker run --name proxy-base64-secret -d -p 81:80 --add-host "backend_host:$HOST_IP" proxy-base64-secret-image

echo "${cyan}Proxy:${NC}"
echo curl http://$HOST_IP

echo "${cyan}Running integration tests:${NC}"
cd test
# make sure npm packages are installed
npm install
# run tests
npm test

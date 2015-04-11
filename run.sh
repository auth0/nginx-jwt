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

echo "${cyan}Prepping files for the proxy (Nginx) container...${NC}"

if [ ! -e "lib/resty/jwt.lua" ]; then
    COMMIT="586a507f9e57555bdd7a7bc152303c91b4a04527"
    curl https://codeload.github.com/SkyLothar/lua-resty-jwt/tar.gz/$COMMIT | tar -xz --strip 1 lua-resty-jwt-$COMMIT/lib
else
    echo "Dependency jwt.lua already downloaded."
fi
if [ ! -e "lib/resty/hmac.lua" ]; then
    COMMIT="67bff3fd6b7ce4f898b4c3deec7a1f6050ff9fc9"
    curl https://codeload.github.com/jkeys089/lua-resty-hmac/tar.gz/$COMMIT | tar -xz --strip 1 lua-resty-hmac-$COMMIT/lib
else
    echo "Dependency hmac.lua already downloaded."
fi
if [ ! -e "lib/basexx.lua" ]; then
    RELEASE="0.1.0"
    curl https://codeload.github.com/aiq/basexx/tar.gz/v$RELEASE | tar -xz --strip 1 basexx-$RELEASE/lib
else
    echo "Dependency basexx.lua already downloaded."
fi
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

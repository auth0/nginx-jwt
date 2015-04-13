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

#TODO: create 2 more images/containers for 'configuration error scenarios':
#      - config-claim_specs-not-table
#      - config-unsupported-claim-spec-type

# build proxy containers and images

for PROXY_DIR in hosts/proxy/*; do
    [ -d "${PROXY_DIR}" ] || continue # if not a directory, skip

    PROXY_NAME="$(basename $PROXY_DIR)"
    echo "${cyan}Building container and image for the '$PROXY_NAME' proxy (Nginx) host...${NC}"

    echo "Deploying Lua scripts and depedencies..."
    rm -rf hosts/proxy/$PROXY_NAME/nginx/lua
    mkdir -p hosts/proxy/$PROXY_NAME/nginx/lua
    cp nginx-jwt.lua hosts/proxy/$PROXY_NAME/nginx/lua
    cp -r lib/ hosts/proxy/$PROXY_NAME/nginx/lua

    echo "Stopping the container and removing the image..."
    docker rm -f "proxy-$PROXY_NAME" &>/dev/null
    docker rmi -f "proxy-$PROXY_NAME-image" &>/dev/null

    echo "Building the new image..."
    docker build -t="proxy-$PROXY_NAME-image" --force-rm hosts/proxy/$PROXY_NAME

    HOST_PORT="$(cat hosts/proxy/$PROXY_NAME/host_port)"
    echo "Staring new container, binding it to Docker host port $HOST_PORT..."
    docker run --name "proxy-$PROXY_NAME" -d -p $HOST_PORT:80 --add-host "backend_host:$HOST_IP" "proxy-$PROXY_NAME-image"
done

echo "${cyan}Proxy:${NC}"
echo curl http://$HOST_IP

echo "${cyan}Running integration tests:${NC}"
cd test
# make sure npm packages are installed
npm install
# run tests
npm test

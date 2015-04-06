#!/bin/sh

cyan='\033[0;36m'
NC='\033[0m' # No Color

# get boot2docker host ip
HOST_IP=$(boot2docker ip)

echo "${cyan}Rebuilding the backend image and restarting its container...${NC}"
docker rm -f backend &>/dev/null
docker rmi -f backend-image &>/dev/null
docker build -t="backend-image" --force-rm hosts/backend
docker run --name backend -d -p 5000:5000 backend-image

echo "${cyan}Restarting the proxy (Nginx) container...${NC}"
docker rm -f proxy &>/dev/null
docker run --name proxy -d -p 80:80 --add-host "backend_host:$HOST_IP" -v "$PWD/hosts/proxy/nginx.conf":/etc/nginx/nginx.conf:ro nginx

echo "${cyan}Proxy:${NC}"
echo curl http://$HOST_IP

echo "${cyan}Running integration tests:${NC}"
cd test
# make sure npm packages are installed
npm install
# run tests
npm test

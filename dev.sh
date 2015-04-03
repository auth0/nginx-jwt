#!/bin/sh

cyan='\033[0;36m'
NC='\033[0m' # No Color

# get boot2docker host ip
HOST_IP=$(boot2docker ip)

echo "${cyan}Rebuilding the API image and restarting the API container...${NC}"
docker rm -f api >/dev/null
docker rmi -f api-image >/dev/null
docker build -t="api-image" --force-rm hosts/api
docker run --name api -d -p 5000:5000 api-image

echo "${cyan}Restarting the proxy container...${NC}"
docker rm -f proxy >/dev/null
docker run --name proxy -d -p 80:80 --add-host "api_host:$HOST_IP" -v "$PWD/hosts/proxy/nginx.conf":/etc/nginx/nginx.conf:ro nginx

echo "${cyan}Proxy:${NC}"
echo curl http://$HOST_IP

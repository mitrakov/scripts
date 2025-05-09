#!/bin/bash

# apt install docker.io         # for Guap, use only the original Docker (not Podman, etc.)
# apt install docker-compose    # or docker-compose-v2, then use "docker compose up -d" (with space)
# apt install redis-tools

# open ports: 22, 80, 81, 82, 5432, 9090
# for wiki,  add +w to "wikidata/" for others recursively
# for redis, add +w to "redis-data/" for group
# openvpn image works on Debian 11; does not work on Centos 9

docker-compose up -d
docker run --rm -d --name file-server -v /root/fileserver-data:/web -p 80:8080 halverneus/static-file-server
docker run --rm -d --name tommyserver -e DB_PASSWORD=541888 -p 9090:8080 mitrakov/tommy-server:24.7.15
docker run --rm -d --name tommypush -v $HOME/tommypush:/etc/tommypush mitrakov/tommypush:24.12.2
docker run --rm -d --name wiki -e DB_TYPE=sqlite -e DB_FILEPATH=/mnt/data/wiki.db -v /root/wikidata:/mnt/data/ -p 82:3000 requarks/wiki:2
docker run --rm -d --name openvpn --cap-add=NET_ADMIN -it -p 1194:1194/udp -p 81:8080/tcp -e HOST_ADDR=mitrakoff.com alekslitvinenk/openvpn

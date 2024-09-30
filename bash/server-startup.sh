#!/bin/bash

# for guap, use only Docker (not Podman)
# for wiki, add +w for others recursively
# for redis, set 777 for redis-data/
# OpenVpn works on Debian 11; does not work on Centos 9
docker-compose up -d
docker run --rm -d --name wiki -e DB_TYPE=sqlite -e DB_FILEPATH=/mnt/data/wiki.db -v /root/wikidata:/mnt/data/ -p 80:3000 requarks/wiki:2
docker run --rm -d --name openvpn --cap-add=NET_ADMIN -it -p 1194:1194/udp -p 81:8080/tcp -e HOST_ADDR=mitrakoff.com alekslitvinenk/openvpn
docker run --rm -d --name file-server -v /root/fileserver-data:/web -p 2000:8080 halverneus/static-file-server
docker run --rm -d --name tommyserver -e DB_PASSWORD=541888 -p 9090:8080 mitrakov/tommy-server:24.5.12

cd tommypush
./restart.sh
cd ..

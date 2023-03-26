#!/bin/bash

# for docker-compose use v1.29.1+ (version from apt install will NOT work)
# for docker-compose, use only Docker (Podman will NOT work)
# for wiki, add +w for others to wikidata/ and wiki.db
# for redis, add +w for group to redis-data/
# OpenVpn works on Debian 11 and Ubuntu 20 LTS; does not work on Centos 9
docker-compose up -d
docker run --rm -d --name wiki -e DB_TYPE=sqlite -e DB_FILEPATH=/mnt/data/wiki.db -v /root/wikidata:/mnt/data/ -p 80:3000 requarks/wiki:2
docker run --rm -d --name openvpn --cap-add=NET_ADMIN -it -p 1194:1194/udp -p 81:8080/tcp -e HOST_ADDR=mitrakoff.com alekslitvinenk/openvpn
docker run --rm -d --name file-server -v /root/fileserver-data:/web -p 2000:8080 halverneus/static-file-server

cd tommypush
./restart.sh
cd ..

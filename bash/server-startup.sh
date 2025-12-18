#!/usr/bin/env bash
set -euo pipefail

# apt install docker.io         # for Guap, use only the original Docker (not Podman, etc.)
# apt install docker-compose    # or docker-compose-v2, then use "docker compose up -d" (with space)
# apt install redis-tools

# open ports: 22, 80, 81, 5432, 9090
# for redis, add +w to "redis-data/" for group
# openvpn image works on Debian 11; does not work on Centos 9

docker-compose up -d
docker run --rm --detach --name fileserver --publish 80:80 --volume $HOME/uploads:/uploads mitrakov/uploadserver:1.0.0
docker run --rm --detach --name tommyserver -e DB_PASSWORD=541888 -p 9090:8080 mitrakov/tommy-server:1.5.1
docker run --rm --detach --name openvpn --cap-add=NET_ADMIN -it -p 1194:1194/udp -p 81:8080/tcp -e HOST_ADDR=mitrakoff.com alekslitvinenk/openvpn
## 0 8-22/2 * * * /root/firebase/aviasales.sh

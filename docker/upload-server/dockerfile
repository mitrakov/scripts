# latest=1.0.1
FROM python:3.13-slim

RUN pip3 install uploadserver
ENV UPL_USER=""
ENV UPL_PASS=""
WORKDIR /uploads
EXPOSE 80
CMD python3 -m uploadserver --allow-replace --basic-auth-upload $UPL_USER:$UPL_PASS 80

# docker build --file uploadserver.dockerfile --platform linux/amd64 -t mitrakov/uploadserver:1.0.1 .
# docker push mitrakov/uploadserver:1.0.1
# docker run --rm --detach --name fileserver --publish 80:80 --volume $HOME/uploads:/uploads -e UPL_USER=admin -e UPL_PASS=admin mitrakov/uploadserver:1.0.1

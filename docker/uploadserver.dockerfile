FROM python:3.13-slim

RUN pip3 install uploadserver
WORKDIR /uploads
EXPOSE 80
CMD ["python3", "-m", "uploadserver", "--allow-replace", "80"]

# docker build --file docker/uploadserver.dockerfile --platform linux/amd64 -t mitrakov/uploadserver:1.0.0 .
# docker push mitrakov/uploadserver:1.0.0
# docker run --rm --detach --name fileserver --publish 80:80 --volume $HOME/uploads:/uploads mitrakov/uploadserver:1.0.0

This example builds a server using [dart2native](https://dart.
dev/tools/dart2native) to run in a container.

### Create a Docker image on your system

```shell
docker build -t server-aot .
```

### Time how long it takes to lauch a server

```shell
time docker run -it -p 8080:8080 --name server-aot-test server-aot
```

Line 30 of `bin/server.dart` causes the server to exit as soon
as it is ready to listen for requests.

### Remove the container

```shell
docker rm -f server-aot-test
```

### Remove the image

```shell
docker image rm server-aot
```

This example builds a [Shelf] server image using the Dart AOT compiler
to run in a container.

### Create a Docker image on your system

```shell
docker build -t server-aot .
```

### Launch a server container

```shell
time docker run -it -p 8080:8080 --name server-aot-test server-vm
```

### Time how long it takes to launch a server

```shell
time docker run -it -p 8080:8080 --name server-aot-test server-aot --quit
```

The `quit` flag causes the server to exit as soon as it is ready to listen
for requests.

### Remove the container

```shell
docker rm -f server-aot-test
```

### Remove the image

```shell
docker image rm server-aot
```

[Shelf]: https://pub.dev/packages/shelf
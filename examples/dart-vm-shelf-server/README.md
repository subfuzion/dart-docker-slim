This example builds a [Shelf] server image using the Dart JIT compiler
to run in a container.

### Create a Docker image on your system

```shell
docker build -t server-vm .
```

### Launch a server container

```shell
time docker run -it -p 8080:8080 --name server-vm-test server-vm
```

### Time how long it takes to launch a server

```shell
time docker run -it -p 8080:8080 --name server-vm-test server-vm --quit
```

The `quit` flag causes the server to exit as soon as it is ready to listen
for requests.

### Remove the container

```shell
docker rm -f server-vm-test
```

### Remove the image

```shell
docker image rm server-vm
```

[Shelf]: https://pub.dev/packages/shelf

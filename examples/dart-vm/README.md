This example gets all the server's dependencies to run the app using the 
Dart VM in a container.

### Create a Docker image on your system

```shell
docker build -t server-vm .
```

### Time how long it takes to lauch a server

```shell
time docker run -it -p 8080:8080 --name server-vm-test server-vm
```

Line 30 of `bin/server.dart` causes the server to exit as soon
as it is ready to listen for requests.

### Remove the container

```shell
docker rm -f server-vm-test
```

### Remove the image

```shell
docker image rm server-vm
```
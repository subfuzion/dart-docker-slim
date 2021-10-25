# ARCHIVED

I'm pleased to announced that the work that I did with this prototype evolved into our official image. This repo is now archived.

Here's the official repo:
https://github.com/dart-lang/dart-docker/

Here's the official image on Docker Hub:
https://hub.docker.com/_/dart

Tony


# subfuzion/dart:slim

The image includes
* Core system runtime dependencies added to the
  [scratch](https://hub.docker.com/_/scratch) image necessary for minimal-
  sized containers for Dart applications, including servers
* A root certificate authority bundle for TLS (needed for making HTTPS requests)
* Name service / DNS support for making HTTP client requests to external hosts

The repo includes tests as well as examples of containerized server apps using
`subfuzion/dart:slim`. You can build and run the examples to see how small a
basic server image is and to time how long it takes to launch a container
until the server app is running and listening for HTTP requests, comparing
the both the Dart VM or the Dart AOT compiler.

Basic details for using the image for Dart AOT- and JIT-compiled apps are
covered below. I published a
[blog post](https://medium.com/google-cloud/build-slim-docker-images-for-dart-apps-ee98ea1d1cf7)
that goes into more detail about the rationale for `subfuzion/dart:slim`
(formerly called `dart-scratch`) and why size matters for images, especially
for modern microservice / serverless apps.

## Dart AOT

If you want the fastest possible application launch and you don't require
Dart reflection (for annotation support, for example), then use
`subfuzion/dart:slim` as shown below. This will build your app using
[`dart compile`](https://dart.dev/tools/dart-tool) ahead-of-time (AOT)
compilation.

Apps that are AOT-compiled start up very fast, exhibit consistent runtime
performance, and don't suffer latency during early runs during a "warm-up"
period the way just-in-time (JIT) compiled code does (see next section).

A minimal server app image will be around 25 MB and when a container is
created the app will launch in sub-second time. This is well-suited for
Function-as-a-Service and other types of jobs which need to execute and
scale quickly. 

```dockerfile
FROM google/dart
# uncomment the following if you want to ensure latest Dart and root CA bundle
#RUN apt -y update && apt -y upgrade
WORKDIR /app
COPY pubspec.yaml .
RUN dart pub get
COPY . .
RUN dart pub get --offline
RUN dart compile exe /app/bin/server.dart -o /app/bin/server

FROM subfuzion/dart:slim
COPY --from=0 /app/bin/server /app/bin/server
# COPY any other directories or files you may require at runtime, ex:
#COPY --from=0 /app/static/ /app/static/
EXPOSE 8080
ENTRYPOINT ["/app/bin/server"]
```

## Dart VM

If your app depends on `dart:mirrors`, then you can't use AOT compilation (see
[Native platform libraries](https://dart.dev/guides/libraries#native-platform-libraries))
to compile the app.

The only option if you need reflection is to use the just-in-time (JIT)
compiler. However, instead of waiting to compile the app the first time it
is run under the Dart VM, it is possible to create a JIT-compiled snapshot
instead, as shown below. This can be loaded by the Dart VM very quickly, just
like the AOT version.

There are a couple of notable differences from AOT-compiled code. JIT-compiled 
code has a warm-up time as the code is optimized dynamically. The advantage is
that JIT-compiled code has the potential to run faster than AOT-compiled
code. This is only really beneficial, however, in a long-running containers.
Containers that perform their tasks quickly and die, and containers that
scale up dynamically in response to loads, may not run long enough to 
benefit from this type of optimization.

Therefore, the main two reasons for using the Dart VM with JIT-compiled
code is if you are creating long-running apps or if you require `dart:mirrors`
support.

A minimal server app image will be close to 50 MB although it should be 
ready in sub-second time to be ready to listen on a socket. 

You may also need to copy one or more system *.dill libraries for your app
to run. You can list available files that can be copied from the base
`google/dart` image by running this docker command:

```shell
docker run --rm google/dart ls -la /usr/lib/dart/lib/_internal
```

For example, dev tool support requires `dartdev.dill`.

If you can't determine the specific file(s) that you need, then copy the entire 
`/usr/lib/dart/lib/_internal` directory, as shown in a comment below (this will
add around ~70MB to your image, however).

```dockerfile
FROM google/dart
# uncomment the following if you want to ensure latest Dart and root CA bundle
#RUN apt -y update && apt -y upgrade
WORKDIR /app
COPY pubspec.yaml .
RUN dart pub get
COPY . .
RUN dart pub get --offline
RUN dart compile kernel -o bin/server.dill bin/server.dart

FROM subfuzion/dart:slim
COPY --from=0 /usr/lib/dart/bin/dart /usr/lib/dart/bin/dart
# You may also need to copy one or more system *.dill libraries
# You can list them by running this docker command:
# docker run --rm google/dart ls -la /usr/lib/dart/lib/_internal
# For example, dev tool support requires dartdev.dill
# If you can't determine the specific file(s) that you need, then
# copy the entire directory (this will add around ~70MB to your image!)
#COPY --from=0 /usr/lib/dart/lib/_internal/*.dill /usr/lib/dart/lib/_internal/
COPY --from=0 /app/bin/server.dill /app/bin/server.dill
# Copy any other directories or files you may require at runtime, ex:
#COPY --from=0 /app/static/ /app/static/
EXPOSE 8080
ENTRYPOINT ["/usr/lib/dart/bin/dart", "/app/bin/server.dill"]
```

## Testing

### Image test

```shell
$ cd test
$ ./dartslim_test.sh
[+] Building 9.7s (15/15) FINISHED

00:00 +0: test/image_test.dart: Is server reachable? ping-test
00:00 +1: test/image_test.dart: Server DNS client tests remote-ping-test
00:00 +2: All tests passed!
```

### Timing tests

```shell
$ time docker pull subfuzion/dart:slim
slim: Pulling from subfuzion/dart
Digest: sha256:5bf1b8083f40b83c437301da991dbca8901ae48c525f56ccda05669040b93e1a
Status: Downloaded newer image for subfuzion/dart:slim
docker.io/subfuzion/dart:slim

real    0m1.656s
user    0m0.156s
sys     0m0.082s

$ docker image ls subfuzion/dart:slim
REPOSITORY       TAG       IMAGE ID       CREATED        SIZE
subfuzion/dart   slim      d92db830c85b   12 hours ago   4.09MB
```

```shell
$ cd ./examples/dart-aot-shelf-server
$ docker build -t server-aot .
[+] Building 11.5s (15/15) FINISHED

$ time docker run -it -p 8080:8080 --name server-aot-test server-aot --quit
Starting server
Serving at http://0.0.0.0:8080
time elapsed: 1 ms

real    0m0.643s
user    0m0.152s
sys     0m0.071s
```

```shell
$ cd ./examples/dart-vm-shelf-server
$ docker build -t server-vm .
[+] Building 4.0s (16/16) FINISHED

$ time docker run -it -p 8080:8080 --name server-vm-test server-vm --quit
Starting server
Serving at http://0.0.0.0:8080
time elapsed: 91 ms

real    0m0.777s
user    0m0.144s
sys     0m0.070s
```

#### Test summary

| Compiler | Build image | Container launch until server listening | main() until server listening |
|----------|-------------|-----------------------------------------|-------------------------------|
| AOT      | 11.5s       | 0.643s                                  | 1ms                           |
| JIT      | 4.0s        | 0.777s                                  | 91ms                          |

Test machine for timing tests

* iMac Pro (2017), 3.2 GHz 8-core Intel Xeon W, 64 GB 2666 MHz DDR4
* Docker engine 20.10.0-beta1
* Dart SDK version: 2.10.4 (stable) on "linux_x64"


---
This is not an official Google project.

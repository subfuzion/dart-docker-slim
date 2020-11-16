## subfuzion/dart:slim

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
COPY --from=0 /app/bin/server.dill /app/bin/server.dill
# COPY any other directories or files you may require at runtime, ex:
#COPY --from=0 /app/static/ /app/static/
EXPOSE 8080
ENTRYPOINT ["/usr/lib/dart/bin/dart", "/app/bin/server.dill"]
```

---
This is not an official Google project.

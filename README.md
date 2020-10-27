## dart-scratch

All the runtime dependencies needed to add to the `scratch` image to run a
minimal-sized container for a Dart application.

The image includes a root certificate authority bundle for TLS (needed
for making HTTPS requests).

There are examples under the `examples` directory if you are interested in
comparing the time until a server app is listening in a container using either
the Dart VM or the Dart AOT compiler.

> NOTE: I have only done a limited amount of testing. I'm working 
> on a [buildpack](https://buildpacks.io/) to support launching in Cloud 
> functions/serverless environments, so feedback is appreciated if you run
> into any [issues](https://github.com/subfuzion/dart-scratch/issues) building
> or running your Dart app with `dart-scratch`.

I published a [blog post](https://medium.com/google-cloud/build-slim-docker-images-for-dart-apps-ee98ea1d1cf7)
that goes into more detail about the rationale for `dart-scratch` and why size 
matters.

## Dart AOT

If you want the fastest possible application launch and you don't require
Dart reflection (for annotation support, for example), then use
`dart-scratch` as shown below. This will build your app using
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
COPY pubspec.* .
RUN dart pub get
COPY . .
RUN dart pub get --offline
RUN dart compile exe /app/bin/server.dart -o /app/bin/server

FROM subfuzion/dart-scratch
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
COPY pubspec.* .
RUN dart pub get
COPY . .
RUN dart pub get --offline
RUN dart compile kernel -o bin/server.snapshot bin/server.dart

FROM subfuzion/dart-scratch
COPY --from=0 /usr/lib/dart/bin/dart /usr/lib/dart/bin/dart
COPY --from=0 /app/bin/server.snapshot /app/bin/server.snapshot
# COPY any other directories or files you may require at runtime, ex:
#COPY --from=0 /app/static/ /app/static/
EXPOSE 8080
ENTRYPOINT ["/usr/lib/dart/bin/dart", "/app/bin/server.snapshot"]
```

---
This is not an official Google project.

## dart-scratch

All the runtime dependencies needed to add to the `scratch` image to run a
minimal-sized container for a Dart application.

The image includes a root certificate authority bundle for TLS (needed
for making HTTPS requests).

There are examples under the `examples` directory if you are interested in
comparing the time until a server app is listening in a container using either
the Dart VM or the `dart2native` AOT compiler.

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
[dart2native](https://dart.dev/tools/dart2native).

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
RUN pub get
COPY . .
RUN pub get --offline
RUN dart2native /app/bin/server.dart -o /app/bin/server

FROM subfuzion/dart-scratch
COPY --from=0 /app/bin/server /app/bin/server
# COPY any other directories or files you may require at runtime, ex:
#COPY --from=0 /app/static/ /app/static/
EXPOSE 8080
ENTRYPOINT ["/app/bin/server"]
```

## Dart VM

If your app depends on `dart:mirrors`, then you can't use `dart2native`
(see [limitations](https://dart.dev/tools/dart2native#known-limitations)),
so use `dart-scratch` as shown below.

A minimal server app image will be around 50 MB and when a container is
created the app can take a number of seconds before it's ready to listen
on a socket. Due to the increased start time this is better suited for
longer-lived app, apps that are less sensitive to job launch time, or
applications that require reflection support (for annotations, for example).

```dockerfile
FROM google/dart
# uncomment the following if you want to ensure latest Dart and root CA bundle
#RUN apt -y update && apt -y upgrade
WORKDIR /app
COPY pubspec.* .
RUN pub get
COPY . .
RUN pub get --offline

FROM subfuzion/dart-scratch
COPY --from=0 /usr/lib/dart/bin/dart /usr/lib/dart/bin/dart
COPY --from=0 /root/.pub-cache /root/.pub-cache
# Copy over the entire app...
COPY --from=0 /app /app
# ...or copy specific files and directories you require at runtime, ex:
#COPY --from=0 /app/bin/server.dart /app/bin/server.dart
#COPY --from=0 /app/lib/ /app/lib/
#COPY --from=0 /app/static/ /app/static/
EXPOSE 8080
ENTRYPOINT ["/usr/lib/dart/bin/dart", "/app/bin/server.dart"]
```

---
This is not an official Google project.

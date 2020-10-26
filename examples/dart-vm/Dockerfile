FROM google/dart
WORKDIR /app
COPY pubspec.* .
RUN pub get
COPY . .
RUN pub get --offline
RUN dart --snapshot=bin/server.snapshot bin/server.dart

FROM subfuzion/dart-scratch
COPY --from=0 /usr/lib/dart/bin/dart /usr/lib/dart/bin/dart
COPY --from=0 /app/bin/server.snapshot /app/bin/server.snapshot
EXPOSE 8080
ENTRYPOINT ["/usr/lib/dart/bin/dart", "/app/bin/server.snapshot"]

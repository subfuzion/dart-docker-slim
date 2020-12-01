FROM google/dart
WORKDIR /app
COPY pubspec.yaml .
RUN dart pub get
COPY . .
RUN dart pub get --offline
RUN dart compile kernel -o bin/server.dill bin/server.dart

FROM subfuzion/dart:slim
COPY --from=0 /usr/lib/dart/bin/dart /usr/lib/dart/bin/dart
COPY --from=0 /app/bin/server.dill /app/bin/server.dill
EXPOSE 8080
ENTRYPOINT ["/usr/lib/dart/bin/dart", "/app/bin/server.dill"]
CMD []

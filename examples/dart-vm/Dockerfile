FROM google/dart
WORKDIR /app
COPY pubspec.* .
RUN pub get
COPY . .
RUN pub get --offline

FROM subfuzion/dart-scratch
COPY --from=0 /usr/lib/dart/bin/dart /usr/lib/dart/bin/dart
COPY --from=0 /root/.pub-cache /root/.pub-cache
COPY --from=0 /app /app
EXPOSE 8080
ENTRYPOINT ["/usr/lib/dart/bin/dart", "/app/bin/server.dart"]
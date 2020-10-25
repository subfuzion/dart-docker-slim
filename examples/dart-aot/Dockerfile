FROM google/dart
WORKDIR /app
COPY pubspec.* .
RUN pub get
COPY . .
RUN pub get --offline
RUN dart2native /app/bin/server.dart -o /app/bin/server

FROM subfuzion/dart-scratch
COPY --from=0 /app/bin/server /app/bin/server
EXPOSE 8080
ENTRYPOINT ["/app/bin/server"]

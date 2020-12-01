FROM google/dart
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
EXPOSE 8080
ENTRYPOINT ["/usr/lib/dart/bin/dart", "/app/bin/server.dill"]

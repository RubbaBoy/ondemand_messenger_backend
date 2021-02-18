FROM google/dart:2.13-dev AS dart-runtime

WORKDIR /app

ADD pubspec.* /app/
RUN pub get
ADD bin /app/bin/
ADD lib /app/lib/
RUN pub get --offline
RUN dart2native /app/bin/ondemand_messenger_backend.dart -o /app/server

FROM frolvlad/alpine-glibc:alpine-3.9_glibc-2.29

COPY --from=dart-runtime /app/server /server

EXPOSE 8090

ENTRYPOINT ["/server"]

# docker build -t rubbaboy/ondemand .
# docker run -p 8090:8090 -d rubbaboy/ondemand:v1.0.0-SNAPSHOT

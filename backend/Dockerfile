FROM dart:stable

WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN mkdir -p /app/build && dart compile exe bin/server.dart -o /app/build/server

ENV HOST=0.0.0.0
ENV PORT=8080

EXPOSE 8080

CMD ["/app/build/server"]

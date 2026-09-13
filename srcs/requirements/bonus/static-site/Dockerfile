FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY server.js /app/server.js
COPY site /app/site

EXPOSE 8080

ENTRYPOINT ["node", "/app/server.js"]
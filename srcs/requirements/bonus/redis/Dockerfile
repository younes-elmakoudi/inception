FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf \
    && sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf \
    && sed -i 's/^daemonize yes/daemonize no/' /etc/redis/redis.conf

EXPOSE 6379

ENTRYPOINT ["redis-server", "/etc/redis/redis.conf"]
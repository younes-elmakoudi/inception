*This project has been created as part of the 42 curriculum by yel-mako.*

# Inception

## Description

Inception sets up a small web infrastructure using Docker and Docker Compose, running inside a dedicated virtual machine. Every service runs in its own container, built from a handwritten Dockerfile — no pre-built images are pulled except the base OS image.

**Mandatory stack:**
- NGINX, the single entrypoint, terminating TLS (1.2/1.3 only) on port 443 and proxying PHP requests to WordPress.
- WordPress with PHP-FPM, provisioned automatically through WP-CLI, with an administrator account and a second author account.
- MariaDB, holding WordPress's data in a persistent volume.

**Bonus stack:**
- Redis, used as WordPress's object cache.
- An FTP server (vsftpd), sharing the WordPress volume for direct file access.
- A standalone static website, served by a small Node.js server.
- Adminer, a database admin panel, routed through the same NGINX instance.
- Fail2ban, watching NGINX's access log for repeated hits on `wp-login.php` and blocking offending IPs through an NGINX-level blocklist.

## Instructions

### Requirements

- A Debian-based VM with Docker Engine and the Compose plugin installed.
- Your login set as the Unix username, since it's used in file paths and the domain name.

### Setup

```bash
git clone git@github.com:younes-elmakoudi/inception.git
cd inception
```

Create the secret files under `secrets/` (see `DEV_DOC.md` for the full list), then:

```bash
make
```

This builds every image and starts the stack. Map `yel-mako.42.fr` to the VM's address in your client's hosts file, then open `https://yel-mako.42.fr`. The certificate is self-signed, so your browser will warn you first — that's expected, not a bug.

See `USER_DOC.md` for day-to-day use and `DEV_DOC.md` for the full developer setup.

## Design choices

**Virtual machines vs Docker.** A VM virtualizes a full machine including its own kernel, giving strong isolation at a heavy resource cost. A container shares the host kernel and gets its isolation from Linux namespaces and cgroups — much lighter, but with a smaller isolation boundary. This project uses one VM as the outer boundary the subject requires, and containers inside it for the actual per-service isolation.

**Secrets vs environment variables.** Environment variables in a Dockerfile or compose file are readable in plain text through `docker inspect` and can end up in logs. Docker secrets mount sensitive values as files under `/run/secrets/` at runtime, never baked into an image layer. `.env` here only holds non-sensitive configuration (domain, database name, usernames); every actual password goes through secrets.

**Docker network vs host network.** `network: host` drops all network isolation and bypasses the requirement that containers communicate over an inspectable, defined network. A custom bridge network gives each container its own namespace and IP, with Docker resolving other containers by service name automatically — this is how NGINX finds WordPress, or WordPress finds MariaDB, without hardcoded IPs.

**Volumes vs bind mounts.** A bind mount ties a container directly to an arbitrary host path with no tracking. A named volume is a Docker-managed object with its own identity, independent of where it's actually stored. Here, both mandatory volumes use the `local` driver's `device` option, which lets a genuine named volume sit at a fixed host path (`/home/yel-mako/data/...`), satisfying both requirements at once.

## Resources

- Docker documentation: https://docs.docker.com
- Compose file reference: https://docs.docker.com/compose/compose-file/
- WP-CLI: https://wp-cli.org
- MariaDB Docker documentation: https://mariadb.com/kb/en/
- NGINX FastCGI documentation: https://nginx.org/en/docs/
- vsftpd documentation and passive-mode configuration notes
- Fail2ban documentation, particularly on custom filters and actions

AI assistance (Claude) was used throughout development as a learning aid — explaining concepts, drafting initial versions of Dockerfiles and scripts, and helping interpret error output during debugging. Every file in this repository was tested and is understood by me; several real issues were found and fixed along the way, including a missing runtime directory that crashed MariaDB on startup, a Debian package pre-populating MariaDB's data directory at build time and defeating the container's own first-run check, a broken WP-CLI download, and a Redis container exiting immediately due to its default `daemonize yes` setting conflicting with how Docker expects a foreground process.
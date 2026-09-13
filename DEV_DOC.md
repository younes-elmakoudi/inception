# Developer Documentation

## Requirements

- A Debian-based VM (VirtualBox or similar), Docker Engine and the Compose plugin installed via Docker's own apt repository, not the `docker.io` distro package.
- Git and SSH access to this repository.
- Your login set as the Unix username, since it's used directly in host paths (`/home/<login>/data`) and the domain name (`<login>.42.fr`).

## Setting up from scratch

Clone the repository:

```bash
git clone git@github.com:younes-elmakoudi/inception.git
cd inception
```

Create the secret files (no trailing newline — use `echo -n`):

```bash
echo -n "<password>" > secrets/db_password.txt
echo -n "<password>" > secrets/db_root_password.txt
echo -n "<password>" > secrets/wp_admin_password.txt
echo -n "<password>" > secrets/wp_user_password.txt
echo -n "<password>" > secrets/ftp_password.txt
```

Check `srcs/.env` for the non-sensitive configuration — domain name, database name, WordPress and FTP usernames. `WP_ADMIN_USER` must not contain `admin` or `administrator` in any case.

## Building and running

The root Makefile wraps Compose:

| Command | Effect |
|---|---|
| `make` / `make up` | creates host data directories, builds every image, starts the stack detached |
| `make down` | stops and removes containers and the network; volumes are kept |
| `make stop` / `make start` | pause / resume without removing containers |
| `make restart` | `down` then `up` |
| `make clean` | `down` plus pruning unused images and build cache |
| `make fclean` | `clean` plus deleting all persisted data under `/home/<login>/data` |
| `make re` | full rebuild from zero |

Under the hood, `make up` runs `docker compose -f srcs/docker-compose.yml up --build -d`.

## Useful commands during development

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs -f <service>
docker compose -f srcs/docker-compose.yml exec <service> bash
docker volume inspect srcs_db_data
docker images
```

## Data persistence

Two named volumes back the mandatory part's persistent state, using the `local` driver's `device` option so each maps to a fixed host path while remaining a proper Docker-managed named volume:

- `srcs_db_data` → `/home/<login>/data/mariadb` — MariaDB's data directory.
- `srcs_wp_data` → `/home/<login>/data/wordpress` — WordPress's full installation, shared read-write between `wordpress` and `nginx`.

Both `init-db.sh` and `init-wp.sh` are idempotent: they check for a marker of prior initialization (`/var/lib/mysql/mysql` for MariaDB, `wp-config.php` for WordPress) and skip provisioning on restart, only running full setup against a genuinely empty volume — i.e. after `make fclean`.

Bonus volumes (`adminer_data`, `nginx_logs`, `blocklist`) use plain Docker-managed storage with no fixed host path, since their content is either disposable or rebuilt fresh from the image on every start.

## Architecture

Browser (HTTPS:443)
│
▼
[nginx] ── TLS termination, static files, FastCGI routing to wordpress and adminer
│ (FastCGI :9000) │ (shared volume: wp_data)
▼ │
[wordpress] ── PHP-FPM, WP-CLI provisioning, Redis object cache client
│ (:3306) │ (:6379)
▼ ▼
[mariadb] [redis]

[ftp] ── shares wp_data, direct file access

[adminer] ── PHP-FPM on :9001, shares its own volume with nginx
[static-site] ── standalone Node.js server, no dependencies
[fail2ban] ── reads nginx's access log, writes nginx's blocklist, reloads nginx via the Docker socket


All containers communicate over the custom `inception` bridge network, resolved by service name through Docker's built-in DNS. Only `nginx` exposes a port to the host; every other container is unreachable from outside the Docker network.

## A design note on fail2ban

Fail2ban doesn't manipulate `iptables` here, which is its traditional mode of operation. Doing that from inside a container would require the `NET_ADMIN` capability and wouldn't actually intercept traffic in NGINX's own network namespace anyway. Instead, fail2ban watches NGINX's access log (shared through a volume) for repeated requests to `wp-login.php`, and on a ban, appends a `deny` line to a config file NGINX includes, then reloads NGINX through a read-only mount of the Docker socket to make the change take effect.

This trades one privileged surface for a narrower one: the container can run exactly one command (`docker exec nginx nginx -s reload`) through the socket, rather than holding raw network-admin rights over the whole host. It's still more privilege than a fully isolated container would have — read-only on the bind mount doesn't fully constrain what's reachable through a live Docker API socket — and that trade-off was made deliberately rather than overlooked.

The filter itself bans on request volume to `wp-login.php`, not strictly on failed-login status, since NGINX's default log format doesn't distinguish a failed WordPress login from a successful one at the HTTP status level (both return 200). In practice this still defends against the realistic threat — automated credential-stuffing against the login endpoint — even though it isn't a precision failed-attempts-only filter.


# User Documentation

How to use the Inception stack — no development background required.

## What's running

- The WordPress site: `https://yel-mako.42.fr`
- The WordPress admin panel: `https://yel-mako.42.fr/wp-admin`
- Adminer, a database admin tool: `https://yel-mako.42.fr/adminer`
- A standalone static page, reachable only from within the Docker network (not exposed externally)
- An FTP server for direct access to the WordPress files
- MariaDB and Redis run in the background and aren't accessed directly

## Starting and stopping

Run these from the root of the repository, on the VM.

Start everything:
```bash
make
```

Stop everything (data is kept):
```bash
make down
```

Pause without removing containers:
```bash
make stop
```

Resume:
```bash
make start
```

Full reset — deletes all site data and rebuilds from scratch:
```bash
make fclean
make
```

## Accessing the site and admin panel

Your browser needs to know `yel-mako.42.fr` points to this server. Add a line to your hosts file (`C:\Windows\System32\drivers\etc\hosts` on Windows, `/etc/hosts` on Linux/macOS):

127.0.0.1 yel-mako.42.fr


(use the VM's actual address instead of `127.0.0.1` if you're not going through port forwarding)

The site uses a self-signed certificate, so the first visit will show a browser warning. This is expected for a local domain with no public certificate authority behind it — proceed past it.

## Credentials

Nothing sensitive is stored in the repository itself.

- `srcs/.env` holds non-sensitive settings: domain name, database name, and the usernames for both WordPress accounts.
- `secrets/` holds the actual passwords, one file per credential (for example `secrets/wp_admin_password.txt`).

The administrator's username is set by `WP_ADMIN_USER` in `.env`; its password is in `secrets/wp_admin_password.txt`.

## Using the FTP server

Connect with any FTP client to the server's address on port 21, using the username set in `FTP_USER` (`.env`) and the password in `secrets/ftp_password.txt`. You'll land directly in the WordPress files directory — anything you upload or edit there is live on the site immediately.

## Using Adminer

Go to `https://yel-mako.42.fr/adminer` and log in with:
- System: MySQL
- Server: `mariadb`
- Username / password: either the WordPress database user (`secrets/db_password.txt`) or `root` (`secrets/db_root_password.txt`)
- Database: `wordpress`

## Checking everything is healthy

```bash
docker compose -f srcs/docker-compose.yml ps
```

All services should show `Up`. If one shows `Restarting`, check its logs:

```bash
docker compose -f srcs/docker-compose.yml logs <service_name>
```

You can also just load `https://yel-mako.42.fr` — if the homepage renders, the core stack (NGINX, WordPress, MariaDB) is working correctly.

## A note on repeated failed logins

Fail2ban watches for repeated attempts on the WordPress login page. If an IP hits `wp-login.php` too many times in a short window, it's temporarily blocked from reaching the site at all — including the static page, Adminer, and everything else behind NGINX, not just the login page. If you get blocked during your own testing, an administrator can lift it manually:

```bash
docker compose -f srcs/docker-compose.yml exec fail2ban fail2ban-client set wordpress-auth unbanip <ip>
```
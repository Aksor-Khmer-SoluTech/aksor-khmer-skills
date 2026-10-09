---
name: aksor-install
description: Install, run, upgrade, back up and troubleshoot an Aksor Khmer BI server with Docker and its deployment.sh script. Use this whenever someone sets up Aksor on a server or PC, edits its .env, runs ./deployment.sh (init, up, update, doctor, backup, restore, logs), puts it behind a domain name or HTTPS, connects their own Postgres/Redis, upgrades to a new release, or hits an error such as "password authentication failed", "no matching manifest", "port is already allocated", the api container being unhealthy, or the portal's sign-in not working — even if they only say "my Aksor server won't start".
---

# Installing and running Aksor

Aksor runs as three Docker Compose stacks on one network, `aksor-network`: Redis (job queue), Postgres (the
database), and the app (api, scheduler, worker, portal, plus an optional jdbc-worker). Everything runs **released
images from Docker Hub**, built for Intel/AMD and ARM; nothing is compiled on the server. The image versions are
written in the repository's `docker-compose.yml`, so the version you run is whatever release you have checked out.

The full guide is https://github.com/Aksor-Khmer-SoluTech/aksor-khmer-bi/blob/main/docs/deployment.md — link the
relevant section in answers. Be concrete: the exact command, where to run it (always from the repository folder),
what it should print, and how to tell it worked.

## First install

Needs Docker with the Compose v2 plugin, ports 8000 (API) and 8080 (portal) free, and access to Docker Hub.

```bash
git clone --depth 1 https://github.com/Aksor-Khmer-SoluTech/aksor-khmer-bi.git
cd aksor-khmer-bi
./deployment.sh init      # once: network, data/ folders, .env with generated passwords (prints the admin password once)
# edit .env: CORS_ALLOWED_ORIGINS = the address people type in the browser; API_PORT / PORTAL_PORT if taken
./deployment.sh up        # checks the machine, starts redis, then postgres, then pulls and starts the app
```

Then open the portal (http://localhost:8080 by default) and sign in as `admin` with the password `init` printed
(also saved in `.env`). API reference: http://localhost:8000/docs.

Run it as `./deployment.sh …`, never `. deployment.sh` — sourcing runs it inside your shell (the script refuses,
but older copies would close the terminal on the first error).

## Every day

| Want to | Command |
|---|---|
| see what's running / logs | `./deployment.sh status` · `./deployment.sh logs` (or `logs api worker scheduler portal`) |
| apply a `.env` change | `./deployment.sh up` (recreates only what changed) |
| restart | `./deployment.sh restart` (or `restart app` / `db` / `redis`) |
| back up now | `./deployment.sh backup` → `./backups/` (database + templates, images, fonts, drivers and the encryption key; newest 14 kept, `BACKUP_KEEP` changes that) |
| restore | `./deployment.sh restore backups/aksor-<time>.sql.gz` (asks you to type `restore`, takes a safety backup first, moves the current `data/` aside rather than deleting it), then `./deployment.sh up` |
| stop | `./deployment.sh down` — data is kept |
| JDBC drivers (Oracle, SQL Server, Db2) | set `JDBC_WORKER_TOKEN` in `.env`, then `./deployment.sh app --profile jdbc up -d jdbc-worker api` |

## Upgrading

1. Read `CHANGELOG.md` for every version between yours and the new one — do what any **Upgrade note** says first
   (new `.env` settings are never merged automatically; compare with `diff .env.example .env`).
2. Back up `.env` outside the folder: `cp -p .env ../aksor.env.bak` (it holds the database password and the admin
   login).
3. `git pull` (or `git checkout v<x.y.z>` for a specific release), then `./deployment.sh update` — it backs up,
   pulls the images `docker-compose.yml` now names, and restarts the app; migrations run as the API starts; Postgres
   and Redis are left alone.

Rollback: check out the older release and `update`; if the database schema changed, restore the backup `update`
made, since migrations only go forward.

## Things that protect data

- **Never** add `-v` to a `docker compose … down` unless you mean to delete the database.
- `data/secrets` (the encryption key) and the database belong together — back up and restore both, or saved
  credentials can no longer be decrypted.
- Don't run `init` again on an existing install, and don't edit the image tags in `docker-compose.yml` by hand —
  versions change through releases.
- A Postgres volume keeps the password it was **created** with, whatever `.env` says later.

## A real server

- **Domain name:** set `CORS_ALLOWED_ORIGINS=https://reports.example.com` in `.env`, and point the portal at the
  API's public URL: copy `portal/public/config.js`, change `window.PORTAL_API_BASE_URL`, set
  `PORTAL_CONFIG_FILE=/path/to/that/config.js`, then `./deployment.sh up`. Portal and API must be on the same site
  (e.g. `reports.example.com` and `api.example.com`, or one domain behind a proxy) because sign-in uses a cookie.
- **HTTPS is not included:** put a reverse proxy (Caddy, nginx, Traefik) in front of ports 8080 and 8000, have it
  send `X-Forwarded-Proto: https` and `X-Forwarded-For`. Don't expose plain HTTP to the internet — passwords and
  tokens would travel unencrypted.
- **Passwords:** use long random values for `PORTAL_PASSWORD` and `POSTGRES_PASSWORD` (`openssl rand -hex 16`);
  `up` refuses a guessable admin password.
- **Your own Postgres/Redis:** set `DATABASE_URL` and `REDIS_URL` in `.env` and skip those two stacks (the network
  is still needed).

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `Postgres refuses POSTGRES_PASSWORD`, or the api log says `password authentication failed for user "aksor"` | The database was created with another password. Put the original back in `.env`, or set the database to the one in `.env`: `docker compose -p aksor-db -f docker-compose.db.yml exec -T postgres psql -U aksor -c "ALTER USER aksor PASSWORD '<the .env password>'"`, then `./deployment.sh up`. An empty `POSTGRES_PASSWORD` means `aksor`. |
| `dependency failed to start: container aksor-app-api-1 is unhealthy` | Read why: `./deployment.sh logs api` — usually the database password (above) or `DATABASE_URL`. |
| `no matching manifest for linux/…` | The machine's CPU is neither Intel/AMD nor ARM (`./deployment.sh doctor` shows it). |
| `pull access denied` / `manifest unknown` | `docker-compose.yml` names a version that isn't released (edited by hand, or an unreleased commit): `git checkout docker-compose.yml` or a release tag, then `update`. |
| Timeouts pulling images | The server can't reach Docker Hub: proxy (configure it for the Docker daemon) or firewall (allow `registry-1.docker.io`, `auth.docker.io`, `production.cloudflare.docker.com`). |
| `port is already allocated` on 8000/8080 | Set `API_PORT` / `PORTAL_PORT` in `.env` (then update `CORS_ALLOWED_ORIGINS`, and `PORTAL_API_BASE_URL` if the API moved), `./deployment.sh up`. |
| Portal loads but sign-in does nothing / "failed to fetch" | `CORS_ALLOWED_ORIGINS` doesn't match the browser address, or `PORTAL_API_BASE_URL` points elsewhere. Check the browser console for a CORS error. |
| Signed in, but a reload sends you back to sign-in | Portal and API on different sites (`localhost` vs `127.0.0.1`, unrelated domains), or plain HTTP with `AUTH_COOKIE_SECURE=true`. |
| `network aksor-network … could not be found` | `docker network create aksor-network` (or run `init`). |
| Containers can't reach the internet (REST/database data sources fail) | Docker forwarding: `sysctl net.ipv4.ip_forward` must be 1; on Ubuntu set UFW `DEFAULT_FORWARD_POLICY="ACCEPT"`; avoid the snap Docker; set DNS in `/etc/docker/daemon.json`. |
| `backup` can't archive `data/` | Start the stack first (the archive is made inside a `postgres:16-alpine` container). |

Building the images from source isn't supported for installs — `--build` is refused on purpose. Run a release.

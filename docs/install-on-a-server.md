# Installing the demonstrator on a server

The demonstrator runs on a laptop with no configuration. Installed on a virtual machine that other people reach over the
network, it needs **a real name, HTTPS and a few closed ports**. All of it is driven by a handful of lines at the top of
`.env`, the `PUBLIC_*` block. Every address in the system (the portal, Keycloak, the tokens' issuer, the redirect URIs, the
Beacon, CORS, the web server's name) is derived from them.

| | Laptop (default) | Server |
|---|---|---|
| `PUBLIC_HOST` | `localhost` | `fhd-demo.example.org` |
| `PUBLIC_SCHEME` | `http` | **`https`** |
| `PORTAL_PORT` | `5173` | `5174` (or `443` behind a proxy) |
| `KEYCLOAK_PORT` | `8080` | `8443` |
| `INTERNAL_BIND` | `127.0.0.1` | `127.0.0.1` |
| Portal | http://localhost:5173 | https://fhd-demo.example.org:5174 |
| Keycloak | http://localhost:8080 | https://fhd-demo.example.org:8443 |

## Why HTTPS on a server

Plain HTTP is acceptable only on `localhost`, where the traffic never leaves the machine. On a network:

* login passwords and the bearer tokens of every API call would cross it in clear, together with the Crypt4GH and SSH keys
  that users register;
* the web application uses PKCE with `S256`, which needs the browser's Web Crypto API, available only on HTTPS or `localhost`:
  the login is expected to fail on `http://my-vm`;
* Keycloak itself refuses plain HTTP from non-private addresses.

`scripts/set-public-host.sh` warns when it is asked for HTTP on a real host name.

## Installation

1. **A DNS name** for the machine, and a firewall that lets the browsers reach `5174` and `8443` (and `443`/`80` if a proxy
   is in front). Nothing else has to be reachable.

2. **Set the address**:

   ```bash
   scripts/set-public-host.sh fhd-demo.example.org --https
   ```

   It edits the `PUBLIC_*` lines of `.env` and prints what to do next. By hand: set `PUBLIC_HOST`, `PUBLIC_HOST_REGEX` (the
   same name with each dot written `[.]`: it is used in a regular expression), `PUBLIC_SCHEME`, `PORTAL_PORT` and
   `KEYCLOAK_PORT`. Behind a reverse proxy that answers on the standard ports, pass `--portal-port 443` (and the port
   under which Keycloak is published).

3. **A certificate** valid for that name, in `certs/`, under these names:

   | File | Read by |
   |---|---|
   | `certs/cert.pem`, `certs/cert-key.pem` | Keycloak (port 8443) |
   | `certs/server.crt`, `certs/server.key` | the web server (port 5174) |

   * **With a certificate of your institution's CA or Let's Encrypt** (the way for a server that real users will use; browsers
     trust it without a warning): copy the files under these names **before the first start**. They are never overwritten.
   * **Without one**, on a fresh install, do nothing: `docker compose up` runs the one-shot service `certs`
     (`scripts/make-certs.sh --if-missing`), which makes a **self-signed** certificate for `PUBLIC_HOST` (and `localhost`) when
     a file is missing. Every browser warns once per user until the certificate is trusted.
   * **If `certs/` already holds certificates** (a laptop install that you now give a real name), the first-start step only
     warns that they are not valid for the new name and keeps them. Replace them with `scripts/make-certs.sh` (self-signed
     for the new name) or with your own files.

   `certs/` is not in git: a clone starts with none.

4. **Start**, which rebuilds the web server because the addresses are compiled into the application:

   ```bash
   docker compose up -d --build
   ```

5. **Check**:

   ```bash
   set -a; . ./.env; set +a
   curl -sk $KEYCLOAK_PUBLIC_URL/realms/fhdportal/.well-known/openid-configuration | python3 -m json.tool | grep '"issuer"'
   curl -sk -o /dev/null -w '%{http_code}\n' $PORTAL_URL/api/schemas            # 200
   ```

   Then open the portal, log in (README, "Register and setup roles"), and run the test of the whole workflow from any
   machine that reaches the server: `cd e2e && npm install && npm run e2e` (it reads the addresses from `../.env`; add
   `E2E_INSECURE_TLS=1` for a self-signed certificate).

### An existing installation

Keycloak reads `init/fhdportal-realm.json` **only into an empty database**. A database that already holds the realm keeps
the old redirect URI (`http://localhost:5173/*`), and the login then fails with *Invalid parameter: redirect_uri*. Either
start from an empty database (`docker compose down && rm -rf fhd-db-data`, which loses everything), or update the client:

```bash
scripts/update-realm-urls.sh
```

It points the `fhdportal-sp` client at `PORTAL_URL` and leaves everything else of the realm alone. If the Keycloak admin
console is not reachable at its public address from where you run it, set `KEYCLOAK_ADMIN_URL`, for example
`KEYCLOAK_ADMIN_URL=http://localhost:8080 scripts/update-realm-urls.sh`.

## What the variables control

| Derived setting | Value | Used by |
|---|---|---|
| `PORTAL_URL` | `PUBLIC_SCHEME://PUBLIC_HOST:PORTAL_PORT` | `VITE_APP_URL`, `VITE_API_ORIGIN`, the Beacon, the realm's redirect URIs |
| `KEYCLOAK_PUBLIC_URL` | `PUBLIC_SCHEME://PUBLIC_HOST:KEYCLOAK_PORT` | `VITE_KEYCLOAK_URL` (the browser), `KEYCLOAK_ISSUER_URL` (the API), `KC_HOSTNAME` (Keycloak) |
| `CORS_ALLOW_ORIGIN` | `^https?://(localhost\|127.0.0.1\|PUBLIC_HOST_REGEX)(:port)?$` | the API |
| `ServerName` | `PUBLIC_HOST` | both virtual hosts of the web server |

Two points that make the setup robust:

* **Keycloak is pinned to its public address** (`KC_HOSTNAME`). The issuer of every token is that address, whichever address
  the request used, so a token requested inside the network (the cron job that plays the DAC does this) and one requested
  through the public name are identical to the API. The "token from the wrong host gives 401" trap of earlier versions is
  gone. Keycloak's back-channel endpoints stay dynamic, so containers keep reaching it as `keycloak:8080`.
* **The realm file takes the portal address from the environment** (`${PORTAL_URL}` in `init/fhdportal-realm.json`,
  filled by Keycloak at the import).

`KEYCLOAK_URL` (`keycloak:8080`) is the *internal* address that the API uses to fetch the signing keys and to call the Admin
API. It does not change.

## Ports

| Port | Service | Listens on |
|---|---|---|
| 5174 | portal, HTTPS | the network |
| 8443 | Keycloak, HTTPS | the network |
| 5173 | portal, plain HTTP | the network (use it only on a laptop; behind a firewall it can stay closed) |
| 8080 | Keycloak, plain HTTP | `INTERNAL_BIND` |
| 5433 | database | `INTERNAL_BIND` |
| 8082 | API (FastCGI front, internal) | `INTERNAL_BIND` |
| 3000 | mock DAC portal | `INTERNAL_BIND` |
| 1025, 8025 | MailHog (SMTP, and a web page that shows every mail of the system) | `INTERNAL_BIND` |

`INTERNAL_BIND` is `127.0.0.1`: those ports answer on the machine itself and not on the network. To use MailHog from your own
computer, tunnel it (`ssh -L 8025:localhost:8025 fhd-demo.example.org`) rather than opening it. `INTERNAL_BIND=0.0.0.0` opens
all of them; `scripts/set-public-host.sh` does that only for an HTTP-only host name and says so.

Close at the firewall what you do not need: Docker publishes ports itself and bypasses some host firewalls (`ufw`).

## Behind the institution's reverse proxy

If the institution terminates TLS in a proxy (nginx, Traefik, an F5), let it forward to the web server (`5173`, plain HTTP, the
proxy being the only thing that reaches it) and Keycloak, and tell the system the ports the *browser* uses:

```bash
scripts/set-public-host.sh fhd-demo.example.org --https --portal-port 443 --keycloak-port 8443
```

Keycloak then has to be told that it sits behind a proxy (`KC_PROXY_HEADERS=xforwarded` in `compose.yml`, and a proxy that
sets `X-Forwarded-Proto` and `X-Forwarded-Host`). This path was not exercised here; the direct HTTPS path above was.

## Before real people use it

The demonstrator realm favours convenience. At least: change the Keycloak administrator password, rotate the client secrets
(`KEYCLOAK_SECRET`, `KEYCLOAK_DAC_SECRET`, and the realm file), switch registration off if an identity provider supplies the
accounts, set `sslRequired` to `external`, and read the hardening table in the
[identity provider guide](integration-identity-provider.md#7-hardening-the-demo-realm-before-production).
The private key of the certificate is in `certs/` (ignored by git): keep it out of shared backups and repositories.

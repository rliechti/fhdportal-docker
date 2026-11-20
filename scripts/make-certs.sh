#!/usr/bin/env bash
# Makes a SELF-SIGNED certificate for PUBLIC_HOST and puts it where the demonstrator reads it:
#   certs/cert.pem + certs/cert-key.pem   Keycloak (port 8443)
#   certs/server.crt + certs/server.key   the web server (port 5174)
#
# `docker compose up` runs this by itself (service "certs", with --if-missing), so a fresh clone needs no certificate.
# A self-signed certificate makes every browser warn. For a server that other people use, put the files of your institution's CA
# (or of Let's Encrypt) under these names instead: they are never overwritten by the first start.
#
#   scripts/make-certs.sh               makes them when missing, or when they are not valid for PUBLIC_HOST (after a change of host)
#   scripts/make-certs.sh --force       always
#   scripts/make-certs.sh --if-missing  only when a file is missing; otherwise it only warns (what the first start does)
#
# PUBLIC_HOST comes from the environment, or else from .env. CERTS_DIR (default: certs) is where the files go.
set -euo pipefail
cd "$(dirname "$0")/.."
mode="auto"
case "${1:-}" in --force) mode="force" ;; --if-missing) mode="if-missing" ;; "") ;; *) echo "unknown option $1" >&2; exit 2 ;; esac

host="${PUBLIC_HOST:-}"
if [ -z "$host" ] && [ -f .env ]; then host="$(sed -n 's/^PUBLIC_HOST=//p' .env | head -n1 | tr -d "\"' ")"; fi
[ -n "$host" ] || { echo "PUBLIC_HOST is not set (environment or .env)" >&2; exit 1; }
dir="${CERTS_DIR:-certs}"
mkdir -p "$dir"

missing=0
for f in cert.pem cert-key.pem server.crt server.key; do [ -s "$dir/$f" ] || missing=1; done
valid_for_host() {
  openssl x509 -in "$dir/cert.pem" -noout -checkhost "$host" 2>/dev/null | grep -q 'does match' \
    && openssl x509 -in "$dir/server.crt" -noout -checkhost "$host" 2>/dev/null | grep -q 'does match'
}

if [ "$missing" = 0 ] && [ "$mode" != "force" ]; then
  if valid_for_host; then
    echo "certificates: $dir/cert.pem and $dir/server.crt are already valid for $host, nothing to do"
    exit 0
  fi
  if [ "$mode" = "if-missing" ]; then
    echo "WARNING: the certificates in $dir are not valid for $host (PUBLIC_HOST). They are kept: browsers will refuse them."
    echo "         Put certificates for $host there, or replace them by a self-signed one: scripts/make-certs.sh"
    exit 0
  fi
fi

if [ "$host" = "localhost" ]; then san="DNS:localhost,IP:127.0.0.1"
elif [[ "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then san="IP:$host,DNS:localhost,IP:127.0.0.1"
else san="DNS:$host,DNS:localhost,IP:127.0.0.1"; fi
cfg="$(mktemp)"; trap 'rm -f "$cfg"' EXIT
cat > "$cfg" <<CFG
[req]
distinguished_name = dn
x509_extensions = v3
prompt = no
[dn]
CN = $host
O = FHDportal demonstrator (self-signed)
[v3]
subjectAltName = $san
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
CFG
openssl req -x509 -newkey rsa:2048 -nodes -days 825 -config "$cfg" -keyout "$dir/cert-key.pem" -out "$dir/cert.pem" 2>/dev/null
cp "$dir/cert.pem" "$dir/server.crt"
cp "$dir/cert-key.pem" "$dir/server.key"
chmod 644 "$dir"/cert-key.pem "$dir"/server.key   # read by the Keycloak and Apache containers (other users)
echo "certificates: made a self-signed certificate for $san, valid 825 days:"
openssl x509 -in "$dir/cert.pem" -noout -subject -enddate
echo "(restart what uses it:  docker compose up -d --force-recreate keycloak webserver)"

#!/usr/bin/env bash
# Makes a SELF-SIGNED certificate for PUBLIC_HOST (from .env) and puts it where the demonstrator reads it:
#   certs/cert.pem + certs/cert-key.pem   Keycloak (port 8443)
#   certs/server.crt + certs/server.key   the web server (port 5174)
# A self-signed certificate makes every browser warn. For a server that other people use, put the files of your institution's CA
# (or of Let's Encrypt) under these names instead: a certificate that is already valid for PUBLIC_HOST is never overwritten.
#
#   scripts/make-certs.sh            only when the certificate is missing or is not valid for PUBLIC_HOST
#   scripts/make-certs.sh --force    always
set -euo pipefail
cd "$(dirname "$0")/.."
force=0; [ "${1:-}" = "--force" ] && force=1

host="$(sed -n 's/^PUBLIC_HOST=//p' .env | head -n1 | tr -d "\"' ")"
[ -n "$host" ] || { echo "PUBLIC_HOST is not set in .env" >&2; exit 1; }
mkdir -p certs

if [ "$force" = 0 ] && [ -f certs/cert.pem ] && [ -f certs/server.crt ] \
   && openssl x509 -in certs/cert.pem -noout -checkhost "$host" 2>/dev/null | grep -q 'does match' \
   && openssl x509 -in certs/server.crt -noout -checkhost "$host" 2>/dev/null | grep -q 'does match'; then
  echo "certs/cert.pem and certs/server.crt are already valid for $host: nothing to do (--force replaces them)"
  exit 0
fi

if [[ "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then san="IP:$host,DNS:localhost,IP:127.0.0.1"; else san="DNS:$host,DNS:localhost,IP:127.0.0.1"; fi
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
openssl req -x509 -newkey rsa:2048 -nodes -days 825 -config "$cfg" -keyout certs/cert-key.pem -out certs/cert.pem 2>/dev/null
cp certs/cert.pem certs/server.crt
cp certs/cert-key.pem certs/server.key
chmod 644 certs/cert-key.pem certs/server.key   # read by the Keycloak and Apache containers (other users)
echo "self-signed certificate for $san, valid 825 days:"
openssl x509 -in certs/cert.pem -noout -subject -enddate
echo "restart:  docker compose up -d --force-recreate keycloak webserver"

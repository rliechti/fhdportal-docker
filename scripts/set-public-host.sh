#!/usr/bin/env bash
# Sets the address under which the demonstrator is reached, in .env (the PUBLIC_* block at its top).
#
#   scripts/set-public-host.sh --local                          laptop: http://localhost:5173, Keycloak http://localhost:8080
#   scripts/set-public-host.sh fhd-demo.example.org --https     server: https://fhd-demo.example.org:5174, Keycloak :8443
#   scripts/set-public-host.sh fhd-demo.example.org --https --portal-port 443 --keycloak-port 8443     behind a proxy
#
# Options:  --portal-port N  --keycloak-port N  the ports the BROWSER uses (default: 5173/8080 for HTTP, 5174/8443 for HTTPS)
# Afterwards (the script says it again): certificate, rebuild of the web server image, realm. See docs/install-on-a-server.md.
set -euo pipefail
cd "$(dirname "$0")/.."

host=""; scheme="http"; portal_port=""; keycloak_port=""
while [ $# -gt 0 ]; do
  case "$1" in
    --local)         host="localhost"; scheme="http" ;;
    --https)         scheme="https" ;;
    --http)          scheme="http" ;;
    --portal-port)   portal_port="${2:?--portal-port needs a value}"; shift ;;
    --keycloak-port) keycloak_port="${2:?--keycloak-port needs a value}"; shift ;;
    -h|--help)       sed -n '2,12p' "$0"; exit 0 ;;
    -*)              echo "unknown option $1" >&2; exit 2 ;;
    *)               host="$1" ;;
  esac
  shift
done
[ -n "$host" ] || { echo "give a host name (or --local); see --help" >&2; exit 2; }
case "$host" in *[!A-Za-z0-9.-]*|"") echo "not a host name: $host (no scheme, no port, no path)" >&2; exit 2 ;; esac
[ -f .env ] || { echo ".env not found (run from the demonstrator folder)" >&2; exit 1; }

if [ "$scheme" = "https" ]; then
  : "${portal_port:=5174}"; : "${keycloak_port:=8443}"
else
  : "${portal_port:=5173}"; : "${keycloak_port:=8080}"
fi
# plain HTTP on a real host name: the plain Keycloak port (8080) has to be reachable, so the internal ports open too
bind="127.0.0.1"
if [ "$scheme" = "http" ] && [ "$host" != "localhost" ]; then bind="0.0.0.0"; fi
regex="${host//./[.]}"   # the dots are written [.] : the value is used in a regular expression, and PHP's dotenv refuses backslashes

tmp="$(mktemp)"
awk -v host="$host" -v regex="$regex" -v scheme="$scheme" -v pp="$portal_port" -v kp="$keycloak_port" -v bind="$bind" '
  /^PUBLIC_HOST=/        { print "PUBLIC_HOST=" host; next }
  /^PUBLIC_HOST_REGEX=/  { print "PUBLIC_HOST_REGEX=" regex; next }
  /^PUBLIC_SCHEME=/      { print "PUBLIC_SCHEME=" scheme; next }
  /^PORTAL_PORT=/        { print "PORTAL_PORT=" pp; next }
  /^INTERNAL_BIND=/      { print "INTERNAL_BIND=" bind; next }
  /^KEYCLOAK_PORT=/      { print "KEYCLOAK_PORT=" kp; next }
  { print }' .env > "$tmp"
grep -q '^PUBLIC_HOST=' "$tmp" || { rm -f "$tmp"; echo ".env has no PUBLIC_* block" >&2; exit 1; }
cat "$tmp" > .env; rm -f "$tmp"

echo "portal:   ${scheme}://${host}:${portal_port}"
echo "keycloak: ${scheme}://${host}:${keycloak_port}"
if [ "$bind" = "0.0.0.0" ]; then
  echo
  echo "WARNING: plain HTTP on a network. Passwords and tokens cross it in clear, and the browser's Web Crypto API (PKCE) is only"
  echo "         available on HTTPS or localhost, so the login is expected to fail. INTERNAL_BIND is now 0.0.0.0: the database, the"
  echo "         API and MailHog listen on the whole network. Use --https (docs/install-on-a-server.md)."
fi
echo
echo "Next:"
if [ "$scheme" = "https" ]; then
  echo "  - a certificate for ${host}:   scripts/make-certs.sh      (or put the files of your CA in certs/, see docs/install-on-a-server.md)"
fi
echo "  - rebuild the web server, which has the addresses built in:   docker compose up -d --build webserver"
echo "  - restart the rest:                                           docker compose up -d"
echo "  - a database that already holds the realm keeps the old redirect URIs: docs/install-on-a-server.md, 'An existing installation'"

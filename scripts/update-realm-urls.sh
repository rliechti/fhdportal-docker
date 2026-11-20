#!/usr/bin/env bash
# Points the web client (fhdportal-sp) of an EXISTING Keycloak database at the portal address of .env (PORTAL_URL).
# Keycloak reads init/fhdportal-realm.json only into an empty database; after a change of PUBLIC_HOST, run this once.
# It sets the root, base and admin URL, the redirect URI (PORTAL_URL/*) and the web origin. Needs: curl, python3, a running Keycloak.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
: "${PORTAL_URL:?PORTAL_URL is not set in .env}" "${KEYCLOAK_PUBLIC_URL:?KEYCLOAK_PUBLIC_URL is not set in .env}"
realm="${KEYCLOAK_REALM:-fhdportal}"
kc="${KEYCLOAK_ADMIN_URL:-$KEYCLOAK_PUBLIC_URL}"      # a self-signed certificate is accepted (-k): this is the administrator's own machine

token() { python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])'; }
at="$(curl -sk -f -X POST "$kc/realms/master/protocol/openid-connect/token" \
      -d grant_type=password -d client_id=admin-cli -d username="${KC_BOOTSTRAP_ADMIN_USERNAME:-admin}" -d password="${KC_BOOTSTRAP_ADMIN_PASSWORD:?}" | token)" \
  || { echo "no admin token from $kc (is Keycloak up, and is KEYCLOAK_ADMIN_URL / the admin password right?)" >&2; exit 1; }
auth="Authorization: Bearer $at"

client="$(curl -sk -f "$kc/admin/realms/$realm/clients?clientId=${VITE_KEYCLOAK_CLIENT_ID:-fhdportal-sp}" -H "$auth")"
id="$(printf '%s' "$client" | python3 -c 'import sys,json; print(json.load(sys.stdin)[0]["id"])')"
printf '%s' "$client" | PORTAL_URL="${PORTAL_URL%/}" python3 -c '
import sys, json, os
c = json.load(sys.stdin)[0]
url = os.environ["PORTAL_URL"]
for key in ("rootUrl", "baseUrl", "adminUrl"):
    c[key] = url
c["redirectUris"] = [url + "/*"]
c["webOrigins"] = [url]
print(json.dumps(c))' > /tmp/fhd-client.json
curl -sk -f -X PUT "$kc/admin/realms/$realm/clients/$id" -H "$auth" -H 'Content-Type: application/json' -d @/tmp/fhd-client.json
rm -f /tmp/fhd-client.json
echo "client ${VITE_KEYCLOAK_CLIENT_ID:-fhdportal-sp}: redirect URI ${PORTAL_URL%/}/*"

#!/usr/bin/env bash
# Gives a registered user the role of the help desk (admin-fega) in Keycloak, without clicking through its console.
#
#   scripts/make-admin.sh <username or e-mail>            admin-fega
#   scripts/make-admin.sh <username or e-mail> submitter  admin-fega and the other roles named (submitter, ...)
#
# The user must have registered in the portal first (README, "Register"). Afterwards the user logs in again (or reloads) to get a
# token with the role. Uses the Keycloak administrator of .env (KC_BOOTSTRAP_ADMIN_*). Needs curl and python3.
set -euo pipefail
cd "$(dirname "$0")/.."
[ $# -ge 1 ] || { sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
who="$1"; shift
extra=("$@")
[ -f .env ] || { echo ".env not found (run from the demonstrator folder)" >&2; exit 1; }
set -a; . ./.env; set +a
realm="${KEYCLOAK_REALM:-fhdportal}"
kc="${KEYCLOAK_ADMIN_URL:-${KEYCLOAK_PUBLIC_URL:?}}"   # a self-signed certificate is accepted (-k): this is the administrator's own machine
json() { python3 -c "import sys,json; d=json.load(sys.stdin); $1"; }

at="$(curl -sk -f -X POST "$kc/realms/master/protocol/openid-connect/token" \
      -d grant_type=password -d client_id=admin-cli -d username="${KC_BOOTSTRAP_ADMIN_USERNAME:-admin}" -d password="${KC_BOOTSTRAP_ADMIN_PASSWORD:?}" \
      | json 'print(d["access_token"])')" \
  || { echo "no admin token from $kc (is Keycloak up? KEYCLOAK_ADMIN_URL can name another address)" >&2; exit 1; }
auth="Authorization: Bearer $at"
enc="$(python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$who")"

# by username, else by e-mail address
id="$(curl -sk -f "$kc/admin/realms/$realm/users?username=$enc&exact=true" -H "$auth" | json 'print(d[0]["id"] if d else "")')"
if [ -z "$id" ]; then
  id="$(curl -sk -f "$kc/admin/realms/$realm/users?email=$enc&exact=true" -H "$auth" | json 'print(d[0]["id"] if d else "")')"
fi
[ -n "$id" ] || { echo "no user '$who' in the realm $realm: register in the portal first (README, \"Register\")" >&2; exit 1; }

for role in admin-fega ${extra[@]+"${extra[@]}"}; do
  rep="$(curl -sk -f "$kc/admin/realms/$realm/roles/$role" -H "$auth")" || { echo "no realm role '$role'" >&2; exit 1; }
  printf '[%s]' "$rep" | curl -sk -f -o /dev/null -X POST "$kc/admin/realms/$realm/users/$id/role-mappings/realm" -H "$auth" -H 'Content-Type: application/json' -d @-
  echo "$who: role $role granted"
done
echo "now: log in again (or reload the portal) to get a token with the new role"

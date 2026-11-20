#!/usr/bin/env bash
# Plays the DAC portal for ONE access request: sends its decision to FHDportal with the token of the dac-cli client.
# The demonstrator has no DAC portal that decides, and no admin screen can (only the DAC may: PATCH /api/requests/{id}).
#
#   scripts/dac-decision.sh --list                   the requests, newest first (id, status, dataset, requester)
#   scripts/dac-decision.sh <request id> APR         approve: the requester gets access
#   scripts/dac-decision.sh <request id> REJ         reject, or revoke an approval
#
# <request id> is the request_id of --list (FHDportal's id) or the id that the DAC portal gave the request.
# Any other status id of GET /api/status-types is accepted by the API too (APR and REJ are the two a DAC sends).
# Run it from the demonstrator folder: it reads .env for the addresses and the secret of dac-cli, and uses docker compose for --list.
# Needs: curl, python3 (and docker compose for --list). See docs/integration-dac-portal.md, section 5.3.
set -euo pipefail
cd "$(dirname "$0")/.."
usage() { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-2}"; }
[ $# -ge 1 ] || usage
case "$1" in -h|--help) usage 0 ;; esac
[ -f .env ] || { echo ".env not found (run from the demonstrator folder)" >&2; exit 1; }
set -a; . ./.env; set +a

if [ "$1" = "--list" ]; then
  docker compose exec -T db psql -U "${POSTGRES_USER:?}" -d "${POSTGRES_DB:?}" -P pager=off -c "
    select request_id, request_status as status, dataset_public_id as dataset, requester_email as requester,
           to_char(action_time, 'YYYY-MM-DD HH24:MI') as changed
    from dataset_request_view order by action_time desc limit 30"
  exit 0
fi

[ $# -eq 2 ] || usage
id="$1"; status="$(printf '%s' "$2" | tr '[:lower:]' '[:upper:]')"
case "$id" in *[!A-Za-z0-9-]*|"") echo "not a request id: $id" >&2; exit 2 ;; esac
case "$status" in *[!A-Z]*|"") echo "not a status id: $2 (APR approves, REJ rejects)" >&2; exit 2 ;; esac

json() { python3 -c "import sys,json; d=json.load(sys.stdin); $1"; }
token="$(curl -sk -f -X POST "${KEYCLOAK_ISSUER_URL:?}/realms/${KEYCLOAK_REALM:?}/protocol/openid-connect/token" \
         -d grant_type=client_credentials -d client_id="${KEYCLOAK_DAC_CLIENT_ID:-dac-cli}" -d client_secret="${KEYCLOAK_DAC_SECRET:?}" \
         | json 'print(d["access_token"])')" \
  || { echo "no token from Keycloak at $KEYCLOAK_ISSUER_URL (is it up? is KEYCLOAK_DAC_SECRET right?)" >&2; exit 1; }

body="$(mktemp)"; trap 'rm -f "$body"' EXIT
code="$(curl -sk -o "$body" -w '%{http_code}' -X PATCH "${PORTAL_URL:?}/api/requests/$id" \
        -H "Authorization: Bearer $token" -H 'Content-Type: application/json' -d "{\"request_status\":\"$status\"}")"
case "$code" in
  200) json 'print("request %s: %s (%s, requested by %s)" % (d["request_id"], d["request_status"], d["dataset_public_id"], d["requester_email"]))' < "$body" ;;
  401) echo "HTTP 401: the token was refused (is dac-cli in KEYCLOAK_ALLOWED_AZP? is the issuer $KEYCLOAK_ISSUER_URL? see docs/check-token.sh)" >&2; exit 1 ;;
  *)   echo "HTTP $code: $(cat "$body")   (unknown request id or status id?)" >&2; exit 1 ;;
esac

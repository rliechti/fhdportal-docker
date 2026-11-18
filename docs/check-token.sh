#!/usr/bin/env bash
# usage: docs/check-token.sh <access token>      (run from the demonstrator folder)
set -a; . ./.env; set +a
python3 - "$1" <<'PY'
import sys, os, json, base64
t = sys.argv[1].split('.')[1]; t += '=' * (-len(t) % 4)
c = json.loads(base64.urlsafe_b64decode(t))
aud = c.get('aud') if isinstance(c.get('aud'), list) else [c.get('aud')]
issuer = os.environ['KEYCLOAK_ISSUER_URL'].rstrip('/') + '/realms/' + os.environ['KEYCLOAK_REALM']
allowed = [a for a in os.environ.get('KEYCLOAK_ALLOWED_AZP', '').split(',') if a]
audience = os.environ.get('KEYCLOAK_EXPECTED_AUDIENCE', os.environ['KEYCLOAK_CLIENT_ID'])
import time
checks = [
  ('iss equals ' + issuer,            c.get('iss') == issuer),
  ('aud contains ' + audience,        audience in aud),
  ('azp in ' + ','.join(allowed),     not allowed or c.get('azp') in allowed),
  ('sub and preferred_username',      isinstance(c.get('sub'), str) and isinstance(c.get('preferred_username'), str)),
  ('not expired',                     c.get('exp', 0) > time.time()),
  ('email present (users only)',      'email' in c or 'service-account-' in c.get('preferred_username', '')),
]
for name, ok in checks: print(('ok   ' if ok else 'FAIL ') + name)
print('roles:', c.get('realm_access', {}).get('roles'))
print('got  : iss=%s azp=%s aud=%s' % (c.get('iss'), c.get('azp'), aud))
PY

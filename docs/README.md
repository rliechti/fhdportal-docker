# Integration guides

Technical documentation for the three systems that a node connects to FHDportal. Each guide describes the endpoints and
messages in both directions, with examples that were run against this demonstrator, and a way to test the integration with
the [end-to-end scenario](../e2e/README.md).

| Guide | For | Contents |
|---|---|---|
| [DAC portal](integration-dac-portal.md) | the developer of an adapter in front of REMS, SD Apply or another governance system | the 11 calls FHDportal makes, the 2 calls the DAC makes (dataset and request decisions), states, REMS mapping, test recipe |
| [Secure Data Archive](integration-secure-data-archive.md) | the operator of an archive or storage service | the inbox contract, the no-broker profile of the demonstrator, the RabbitMQ message contract, download credentials |
| [Installing on a server](install-on-a-server.md) | the person who puts the demonstrator on a VM | `PUBLIC_HOST` and HTTPS, certificates, ports, an existing installation, reverse proxy |
| [Identity provider](integration-identity-provider.md) | the Keycloak or federation administrator | the token contract, clients and roles, federating an upstream provider, troubleshooting 401, hardening |

Conventions used in the examples:

```bash
set -a; . ./.env; set +a                      # KEYCLOAK_*, PORTAL_URL, DAC_API, … from the demonstrator folder
API=$PORTAL_URL/api                           # the portal's API, as seen by the browser (http://localhost:5173/api on a laptop)
# tokens: request them at $KEYCLOAK_ISSUER_URL (http://localhost:8080 on a laptop); Keycloak is pinned to that address, it is the "iss"
```

[`check-token.sh`](check-token.sh) decodes an access token and compares it with the configuration (iss, aud, azp, claims).
[`../scripts/dac-decision.sh`](../scripts/dac-decision.sh) plays the DAC for one access request (approve or reject).

The demonstrator itself (what to click, step by step) is in the [README](../README.md).

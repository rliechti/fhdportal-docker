# Integration guides

Technical documentation for the three systems that a node connects to FHDportal. Each guide describes the endpoints and
messages in both directions, with examples that were run against this demonstrator, and a way to test the integration with
the [end-to-end scenario](../e2e/README.md).

| Guide | For | Contents |
|---|---|---|
| [DAC portal](integration-dac-portal.md) | the developer of an adapter in front of REMS, SD Apply or another governance system | the 11 calls FHDportal makes, the 2 calls the DAC makes (dataset and request decisions), states, REMS mapping, test recipe |
| [Secure Data Archive](integration-secure-data-archive.md) | the operator of an archive or storage service | the inbox contract, the no-broker profile of the demonstrator, the RabbitMQ message contract, download credentials |
| [Identity provider](integration-identity-provider.md) | the Keycloak or federation administrator | the token contract, clients and roles, federating an upstream provider, troubleshooting 401, hardening |

Conventions used in the examples:

```bash
API=http://localhost:5173/api                 # the portal's API, as seen by the browser
set -a; . ./.env; set +a                      # KEYCLOAK_*, DAC_API, … from the demonstrator folder
# tokens: request them at $KEYCLOAK_ISSUER_URL (https://0.0.0.0:8443): the host becomes the token's "iss"
```

[`check-token.sh`](check-token.sh) decodes an access token and compares it with the configuration (iss, aud, azp, claims).

The demonstrator itself (what to click, step by step) is in the [README](../README.md).

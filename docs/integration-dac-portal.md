# Integrating a DAC portal (for example REMS) with FHDportal

Technical reference for the team that connects a Data Access Committee (DAC) system to FHDportal: the contract in both
directions, with examples that were run against this demonstrator. It is written from the API code and from the
end-to-end scenario in [`../e2e`](../e2e/README.md), and it complements the MS5.3 report (sections 4 and 5.3, annexes B and C).

Companion documents: [secure data archive](integration-secure-data-archive.md) · [identity provider](integration-identity-provider.md).

**Who reads this**: the developer of a DAC adapter, for example a service in front of REMS or SD Apply.
**What you get**: the eleven calls FHDportal makes to your system, the two calls your system makes to FHDportal, the states
that move, and a test recipe.

---

## 1. Principle

The DAC portal is the system of record for *who may access what*. It holds the policies, serves the application forms,
and is where the committee decides. FHDportal never decides: it has no code path that approves an access request on its own
authority. It registers datasets for governance, shows the DAC's forms to the requester, and enforces the decision it is told.

```mermaid
sequenceDiagram
    autonumber
    actor S as Submitter
    actor R as Requester
    participant F as FHDportal API
    participant D as DAC portal (your adapter)
    participant K as Keycloak (shared realm)

    Note over S,D: A. Submission: a policy is attached to every dataset
    S->>F: GET /api/dacs
    F->>D: GET /policies, GET /dacs/{id}
    S->>F: PUT dataset {policy_id}
    F->>D: GET /policies/{id}, GET /submissions?datasetID, POST /submissions
    S->>F: PATCH study {status_type_id: SUB}
    D->>K: client credentials (dac-cli)
    D->>F: PATCH /api/submissions/{study}/datasets/{dataset} {policy_status: valid}
    Note over F: dataset and study become approved (APR); the help desk publishes (PUB)

    Note over R,D: B. Access request
    R->>F: POST /api/dacs/requests {datasetIDs}
    F->>D: POST /datarequests
    R->>F: GET /api/dacs/requests/{id}/form
    F->>D: GET /datarequests/{id}/requester-form
    R->>F: PATCH /api/dacs/requests/{id} {formValues, status: pending}
    F->>D: PATCH /datarequests/{id}
    R->>F: GET .../daa, then PATCH with the signed DAA
    F->>D: GET /datarequests/{id}/daa, POST /datarequests/{id}/attachments
    Note over F: request status SUB (submitted)
    D->>F: PATCH /api/requests/{id} {request_status: APR}
    Note over F: approved: download credentials are issued (needs the archive)
```

Two properties to build on:

* **One realm.** FHDportal forwards the *caller's own* bearer token to your system on every outbound call. Your system
  validates it against the same Keycloak realm, so a user is the same principal on both sides and no identity mapping is
  needed. (The demonstrator mock does not validate tokens; a real DAC must.)
* **Two inbound calls**, both made with a `dac-cli` service token. MS5.3 mentions one; the dataset-level approval of
  section 5.2 is the second. In the demonstrator a cron job (`init/cron_approve.php`) plays that second call by writing to
  the database; see section 8.

## 2. Configuration

All values live in `../.env` (the file docker compose reads; the API container mounts it read-only).

| Variable | Demonstrator value | Meaning |
|---|---|---|
| `DAC_API` | `http://dac-api:3000` | Base URL of your DAC portal. **The only thing to change to plug in your adapter.** No trailing slash. |
| `KEYCLOAK_DAC_CLIENT_ID` | `dac-cli` | The `azp` the API requires for a DAC service token. |
| `KEYCLOAK_DAC_SECRET` | *(in `.env`)* | Secret of that client. Your adapter needs it, FHDportal does not. |
| `KEYCLOAK_ALLOWED_AZP` | `fhdportal-sp,fhdportal-cli,dac-cli` | Clients whose tokens the API accepts. **Must include `dac-cli`.** |
| `KEYCLOAK_ISSUER_URL` | `https://0.0.0.0:8443` | Issuer the API expects in `iss`. Your adapter must obtain its token from this URL (see 5.1). |
| `HELPDESK_EMAIL`, `GOS_DAC_EMAIL` | `.env` | Addresses that receive the notification mails (MailHog in the demonstrator). |

In the realm (`init/fhdportal-realm.json`): a confidential client `dac-cli` with *service accounts* enabled, the realm role
`dac-cli` on its service account, and the audience mapper `fhdportal-api-audience` (adds `fhdportal-cli` to `aud`).

To plug in an adapter, edit `DAC_API` and restart the API: `docker compose restart api`.

## 3. Identifiers and states

| Name | Format | Where it comes from |
|---|---|---|
| dataset id | UUID (internal) or `CHFEGAD00000000056` (public) | FHDportal. Requests accept either; outbound calls send the UUID. |
| policy id | UUID | Your system: `id` in `GET /policies`. |
| `externalID` | UUID | FHDportal. Sent on `POST /submissions`; it is the id of the dataset-to-policy link in FHDportal. Store it, it is how you map a decision back. |
| DAC `userID` | Keycloak `sub` | Your system: `members[].userID` in `GET /dacs/{id}` must equal the member's Keycloak subject. |
| request id | UUID | Your system: `id` of `POST /datarequests`. FHDportal keeps it as `dac_request_id`. |

Status ids (`GET /api/status-types`, requires a token). Those a DAC integration moves:

| Id | Name | On a dataset / study | On an access request |
|---|---|---|---|
| `DRA` | draft | being edited | |
| `SUB` | submitted | waits for the DAC | request with a signed DAA, waits for the DAC |
| `APR` | approved | accepted by the DAC, waits for the help desk | **access granted** |
| `PUB` | published | public in the catalogue | |
| `REV` | revised | returned to the submitter | |
| `REJ` | rejected | | **access refused or revoked** |
| `DAP` | daa_pending | | form sent, agreement not yet signed |

Life of an access request: *(none)* → `DAP` (first form `PATCH` with `status: pending`) → `SUB` (signed DAA attached) →
`APR` or `REJ` (your decision) → any other id later, including `REJ` after `APR`, which revokes.

## 4. Outbound contract: what FHDportal calls on your system

Every call carries `Authorization: Bearer <token of the user who acted>`. Only HTTP 200 is a success for the calls below
(except `POST /submissions`, where any 2xx is). The mock in [`../dac-data`](../dac-data) returns canned bodies for all of
them; the bodies shown here are its own.

| # | Call | FHDportal triggers it when | Used for |
|---|---|---|---|
| 1 | `GET /dacs/{dacId}` | listing policies; policy lookups | DAC name, description, members |
| 2 | `GET /policies?limit=99&offset=0` | `GET /api/dacs` (policy picker) | list policies, paginated |
| 3 | `GET /policies/{policyId}` | a policy is attached to a dataset | policy and its DAC |
| 4 | `GET /policies/{policyId}/{form}?format=jsonform` | `GET /api/dacs/{dataset}/policies/{policy}/{form}` | forms of a policy (`requester-form`, `markdown`) |
| 5 | `GET /submissions?datasetID={uuid}` | a policy is attached; status lookups | which policy is registered for a dataset |
| 6 | `POST /submissions` | a policy is attached to a dataset | register the dataset for review |
| 7 | `POST /datarequests` | `POST /api/dacs/requests` | open an access request |
| 8 | `GET /datarequests/{id}/requester-form` | `GET /api/dacs/requests/{id}/form` | the application form |
| 9 | `POST /datarequests/{id}/attachments?fileName=&iri=` | `PATCH /api/dacs/requests/{id}` with `attachmentFiles` | upload a document |
| 10 | `PATCH /datarequests/{id}` | `PATCH /api/dacs/requests/{id}` | save form values, attachment ids |
| 11 | `GET /datarequests/{id}/daa` | `GET /api/dacs/requests/{id}/daa` | the Data Access Agreement, as PDF |

### 4.1 Policies and DACs (calls 1 to 4)

```bash
curl -s http://localhost:3000/policies
```
```json
{ "data": [ { "id": "f3a00e9c-0565-40ca-94da-0a21b2840169",
              "dacID": "3ca06160-2000-40ce-b906-4a796375de61",
              "title": "Standard Data Access Policy",
              "description": "Mock policy for local development." } ],
  "pagination": { "totalCount": 1, "offset": 0, "limit": 1 } }
```

FHDportal pages with `limit`/`offset` until `offset + limit >= totalCount`, and calls `GET /dacs/{dacID}` once per distinct
DAC:

```bash
curl -s http://localhost:3000/dacs/3ca06160-2000-40ce-b906-4a796375de61
```
```json
{ "name": "Test DAC",
  "description": "Mock Data Access Committee for local development.",
  "members": [ { "userID": "0da28851-fe45-4fe4-8c88-86a99218711c", "email": "dac-member@example.org" } ] }
```

`GET /policies/{id}` returns `{title, dacID, description}`. `GET /policies/{id}/{form}?format=jsonform` returns
`{ "jsonForms": { "schema": …, "uischema": …, "data": … } }`; `{form}` is an opaque name that you define.

### 4.2 Registering a dataset (calls 5 and 6)

When a submitter attaches a policy, FHDportal first asks whether the dataset is already registered:

```bash
curl -s 'http://localhost:3000/submissions?datasetID=1a47ca2f-47fa-4f6f-9b87-b2b12b9ec017'
# {"data": []}
```

and, if there is no entry (or the entry is `revoked`), registers it:

```http
POST /submissions
{ "datasetID": "1a47ca2f-47fa-4f6f-9b87-b2b12b9ec017",
  "externalID": "9c1e5c7a-…",            
  "policyID":   "f3a00e9c-0565-40ca-94da-0a21b2840169" }
```

A found entry looks like (flat `datasetID`/`policyID` or nested `dataset.id`/`policy.id` are both read):

```json
{ "data": [ { "id": "…", "status": "approved", "externalID": "…",
              "dataset": { "id": "…" }, "policy": { "id": "…", "dacID": "…", "title": "…" } } ] }
```

### 4.3 The access request (calls 7 to 11)

```http
POST /datarequests
{ "datasetIDs": ["1a47ca2f-47fa-4f6f-9b87-b2b12b9ec017"] }
→ 200 { "id": "d28d3af3-…", "status": "draft", "datasetIDs": ["…"] }
```

`GET /datarequests/{id}/requester-form` returns a [JSON Forms](https://jsonforms.io) document. FHDportal renders it and
forwards the values; neither the questions nor their validation are FHDportal's.

```json
{ "jsonForms": {
    "schema":   { "type": "object", "title": "Requester Form",
                  "properties": { "general": { "type": "object", "title": "General Information",
                                    "properties": { "first-name": { "type": "string", "readOnly": true } } },
                                  "attachments": { "type": "array", "x-renderer": "attachment-upload-binary",
                                                   "x-iri": "https://ontology.swisscustodian.ch/schema/Measure" } } },
    "uiSchema": { "type": "VerticalLayout", "elements": [ … ] },
    "initialValues": { "general": { "first-name": "Local", "last-name": "Developer" } } } }
```

The mock's form has the sections `general`, `attachments`, `measures`, `processing`, `project` and `purposes`. The portal
reads `schema`, `uiSchema` (also `uischema`) and `initialValues` (also `data`).

Vendor keys recognised in the schema: `x-renderer: attachment-upload-binary` (a file picker) and `x-iri` (the type of the
attachment). The form must be readable by the user who owns the request.

The portal then sends the values (the body is FHDportal's own, derived from what the requester typed):

```http
PATCH /datarequests/{id}
{ "formValues": { "general": { … } }, "attachmentIDs": ["…"], "attachments": [ … ] }
→ 200 { "id": "…", "status": "draft", "attachmentIDs": [], "formValues": {} }
```

The Data Access Agreement is a PDF: `GET /datarequests/{id}/daa` → `200`, `Content-Type: application/pdf`.

The signed agreement comes back as a raw binary body:

```http
POST /datarequests/{id}/attachments?fileName=signed-daa.pdf&iri=https%3A%2F%2Fontology.swisscustodian.ch%2Fschema%2FSignedDAA
Content-Type: application/pdf
<bytes>
→ 200 { "id": "cfbd6181-…" }
```

**The signed-DAA IRI** `https://ontology.swisscustodian.ch/schema/SignedDAA` is special: FHDportal reads it as the
countersigned agreement and moves the request to `SUB`. Your adapter must accept it, and return the new attachment `id`.

**Errors.** Answer a non-200 status with `{ "id", "title", "message", "details" }`. FHDportal turns every non-200 into
a generic error for the user (`Unable to create data request`, …) and writes the status to its log; per MS5.3, a populated
`details` marks a validation problem the requester can fix.

## 5. Inbound contract: what your system calls on FHDportal

### 5.1 Getting a token

The DAC authenticates with the **client credentials** grant of the `dac-cli` client:

```bash
# from the demonstrator folder; the secret is in .env
set -a; . ./.env; set +a
TOKEN=$(curl -sk -X POST "https://0.0.0.0:8443/realms/fhdportal/protocol/openid-connect/token" \
  -d grant_type=client_credentials -d client_id=dac-cli -d client_secret="$KEYCLOAK_DAC_SECRET" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
```

The decoded token (checked on the demonstrator):

```json
{ "iss": "https://0.0.0.0:8443/realms/fhdportal",
  "azp": "dac-cli",
  "aud": ["fhdportal-cli", "realm-management", "account"],
  "preferred_username": "service-account-dac-cli",
  "realm_access": { "roles": ["dac-cli", "offline_access", "uma_authorization", "default-roles-fhdportal"] } }
```

The API accepts it only if **all** of this hold: `iss` equals `KEYCLOAK_ISSUER_URL` + `/realms/fhdportal`, `aud` contains
`fhdportal-cli`, `azp` is in `KEYCLOAK_ALLOWED_AZP`, and (for the DAC calls) the role `dac-cli` is present **and** `azp`
equals `KEYCLOAK_DAC_CLIENT_ID`. A token for a human who holds the role is not enough.

> **Gotcha, seen while writing this page.** The same request sent to `https://localhost:8443` returns a valid-looking
> token whose `iss` is `https://localhost:8443/…`; the API then answers **401 Unauthorized**, with no hint. Fetch the token
> from the URL that `KEYCLOAK_ISSUER_URL` names (`https://0.0.0.0:8443`; the certificate is self-signed, hence `-k`).
> Tokens live 300 seconds: request a new one for each batch of calls.

### 5.2 Dataset decision: approve or send back

`PATCH /api/submissions/{study_id}/datasets/{dataset_id}`, `{dataset_id}` a UUID or a public id (`CHFEGAD…`).

```bash
# approve the dataset under the policy it was submitted with
curl -sk -X PATCH "http://localhost:5173/api/submissions/CHFEGAS00000000038/datasets/CHFEGAD00000000059" \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"policy_id":"f3a00e9c-0565-40ca-94da-0a21b2840169","policy_status":"valid"}'
# HTTP 204
```

| Body field | Meaning |
|---|---|
| `policy_id` (UUID) or `policy_public_id` | The policy of the decision. It must be the one linked to the dataset, otherwise the call fails with 500 (`this policy was not linked to this dataset`). An unknown id is silently ignored (204, nothing changes). |
| `policy_status` | A string starting with `valid` approves (the link becomes active). `reject` sends the dataset back. |

Effects, observed on a study of two datasets:

* **approve**: the dataset becomes `APR`; when every non-deleted dataset of the study is `APR`, the study becomes `APR` and
  a mail goes to `HELPDESK_EMAIL`. Publication (`PUB`) is the help desk's, from *Admin → Dataset Reviews*, and is what
  releases the dataset to the catalogue.
* **reject**: the policy link is deleted; the dataset **and its study** go back to the submitter, as `DRA` if they were
  `SUB`, as `REV` otherwise. The status cascade applies to every part of the study: rejecting one dataset of two returned
  both datasets and the study to `REV`. Deleted parts stay deleted.

A user that is a *member* of the dataset's DAC (the Keycloak `sub` appears in `members[].userID` of the policy's DAC) may
make the same call with their own token.

### 5.3 Request decision: grant or revoke access

`PATCH /api/requests/{request_id}`. `{request_id}` is FHDportal's request id or **your own request id** (the one
`POST /datarequests` returned).

```bash
curl -sk -X PATCH "http://localhost:5173/api/requests/$REQUEST_ID" \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"request_status":"APR"}'
```
The answer is the request as the portal now shows it (identifiers from an e2e run; `request_status` as after `APR`):

```json
{ "request_id": "74c57ec3-22ff-4664-985c-e0e48844c947",
  "dataset_id": "1a47ca2f-…", "dataset": "Variant calling for … cohort", "dataset_public_id": "CHFEGAD00000000056",
  "study": "…", "study_public_id": "CHFEGAS00000000036",
  "requester": "E2E Submitter", "requester_email": "e2e-submitter@example.org",
  "c4gh_public_key": "jfSMojYv9w5LGZY/ozvFmJ6xi3jyOOX2KtuPtIr6hoA=",
  "request_status": "approved", "action_time": "2026-11-18 13:55:21.352197",
  "doa_bucket_name": null, "doa_endpoint": null, "doa_access_key": null, "doa_secret_key": null, "doa_session_token": null }
```

| `request_status` | Effect |
|---|---|
| `APR` | The request is `approved`. FHDportal asks the archive for download credentials for the requester's Crypt4GH key (a no-op, with a successful answer, when messaging is off: see the [archive guide](integration-secure-data-archive.md)). |
| `REJ` (or any other valid status id) | The status changes. If it was `APR`, the download access is revoked at the archive. |

The body is just `{"request_status": "<id>"}` with an id of `status_type` (section 3).

Errors, as observed:

| Case | Answer |
|---|---|
| no token, wrong `azp`, user token, expired token, wrong issuer | `401 {"message":"Unauthorized"}` |
| request id unknown | `500 ["Dataset request not found"]` (a 404 would be the correct code) |
| status id unknown (for a known request) | `500 ["Request status is not valid"]` |

## 6. Mapping REMS and SD Apply to the contract

For an adapter in front of REMS (SD Apply is a REMS deployment). Translation, except the last row, is driven by FHDportal.

| FHDportal / contract | REMS concept | Adapter's job |
|---|---|---|
| `GET /policies`, `/policies/{id}` | catalogue item with its workflow | list items; project `id`, `title`, `description`, `dacID` |
| `GET /dacs/{id}` | workflow handlers | project the handlers; `userID` **must be the Keycloak `sub`** |
| `POST /submissions` | create or bind a catalogue item for the dataset | persist `externalID` and `datasetID` with the item |
| `GET /submissions?datasetID=` | catalogue item lookup | return `id`, `status`, `externalID`, `policyID` |
| `POST /datarequests` | create a draft application | return its id |
| `GET /datarequests/{id}/requester-form` | application form | **translate to JSON Forms** (dominant cost) |
| `PATCH /datarequests/{id}` | save draft | apply `formValues` |
| `POST …/attachments` | attachment and licence acceptance | store; on the signed-DAA IRI, accept the licence |
| `GET …/daa` | licence document | return it as PDF |
| `PATCH /api/requests/{id}` and `PATCH /api/submissions/…/datasets/…` | application events | **observe** `application/approve`, `application/revoke` and `closed` (poll the REMS API or take the event) and call FHDportal |

Advice:

1. Keep a table `FHDportal externalID ⇄ REMS application / catalogue item`: you need it for the decision callbacks.
2. Author the requester form directly as a JSON Forms document and keep it next to the REMS form. It saves most of the
   translation work.
3. Use the same Keycloak realm. If REMS has its own, you reintroduce the identity mapping that the shared realm removes.
4. A `closed` or `revoked` application should send `{"request_status":"REJ"}`.
5. The callbacks are the only calls your adapter starts. Everything else is a response.

## 7. Test recipe for an adapter

1. **Smoke test the eleven endpoints** with `curl`, as in section 4, and compare the bodies with those shown.
2. **Run the scenario**, switching `DAC_API` to your adapter and restarting the API. Phases 4 and 7 of the end-to-end test
   cover what the DAC touches:

   | Step | Checks |
   |---|---|
   | 4.2 | the policy picker lists your policy and the policy attaches to both datasets |
   | 4.3 | the study submits (a policy per dataset) |
   | 5.1–5.5 | the dataset decision reaches FHDportal and the help desk can publish |
   | 7.1 | `POST /datarequests` works and returns an id |
   | 7.2 | the form is served and accepted |
   | 7.3 | the DAA downloads as a PDF, and the signed DAA moves the request to submitted |
   | 7.4 | only the `dac-cli` client may decide a request (401 for the submitter and the help desk) |
   | 7.5, 7.6 | `APR` reaches FHDportal and shows for the requester and the help desk |
   | 7.7, 7.8 | `REJ` revokes; an unknown status is refused |

   ```bash
   cd e2e && cp .env.example .env && npm install && npm run e2e
   ```
   The test plays the DAC itself in 5.1 (cron) and 7.5/7.7 (token). Against a real adapter, replace those steps by the
   decision that your system sends, and keep every other step.
3. **Conformance checklist** (MS5.3 §5.3):
   - [ ] the eleven endpoints, with the bodies and status codes of section 4
   - [ ] the two inbound calls wired, with a `dac-cli` service token
   - [ ] the `dac-cli` client has the client-credentials grant, the `dac-cli` realm role and the audience mapper
   - [ ] bearer tokens of the shared realm are accepted on every outbound call
   - [ ] the signed-DAA IRI is recognised
   - [ ] `externalID` is stored on registration and returned on lookup
   - [ ] `userID` of DAC members is the Keycloak `sub`
   - [ ] errors use the `{id, title, message, details}` envelope

## 8. Limits of the demonstrator, and things to know

* The mock in `dac-data/` is **stateless and one-directional**: canned answers, no token validation, and it never decides.
* `init/cron_approve.php` stands in for the dataset decision of section 5.2: every minute it approves submitted datasets by
  writing to the database. It does **not** call the API, so the dataset decision is not exercised end to end. Making the
  cron job call `PATCH …/datasets/…` with a `dac-cli` token would test the real contract.
* A request can be opened only for a dataset that is published (or revised/re-submitted) **and whose release date has
  arrived**, and the requester needs a Crypt4GH key registered (e2e step 0.3). If either is missing, the form `PATCH`
  still answers 200 but FHDportal does **not** register the request: it never appears in `GET /api/requests` and the later
  decision finds nothing to update.
* `GET /api/dacs` is rate limited to 5 calls a minute.
* Unknown request ids and invalid statuses answer 500 on `PATCH /api/requests/{id}` (see 5.3).
* Everything here assumes the demo realm, which accepts plain HTTP and open registration; see the
  [identity provider guide](integration-identity-provider.md) for production settings.

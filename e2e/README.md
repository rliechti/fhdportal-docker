# End-to-end test of the FHDportal demonstrator

An API-level test (Playwright, TypeScript) of the whole path through the demonstrator in the folder above:
accounts, test data, uploaded files, bundle upload and editing, policy, submission, publication, catalogue, access request
and the decision of the DAC. It needs no browser, and no human step.

It comes from the staging test of `fega-api/e2e` and keeps its structure (numbered steps, one ordered story, an evidence
report). What differs is in the table below: **the SDA and the DAC are not the real ones** here.

## Run

```bash
cd .. && docker compose up --build -d      # the demonstrator, once
cd e2e
npm install
cp .env.example .env                       # sets E2E_INSECURE_TLS=1, the demonstrator serves a self-signed certificate
npm run e2e                                # about 15 seconds; npm run unit: the helpers only, no demonstrator needed
```

Needs on the machine: Node, PHP with the `zip` extension, `fega-cli` in the `$PATH` (or `E2E_FEGA_CLI="php /path/to/fega.phar"`),
and `docker compose` (to run the cron jobs of the API container on demand: without it the test waits for their next minute).

Everything has a default that fits a stock demonstrator: the Keycloak address, realm, client secrets and admin account are
read from `../.env`, the file docker compose reads. `.env.example` lists what can be changed.

Output: `results/reports/<bundle>/test-report.md` (steps, evidence files, known bugs), `results/html`, `results/junit.xml`.
Every run leaves a study and its published datasets in the demonstrator, named `DEMO-E2E-<date>-<time>`.

## The scenario

| Phase | What it does | Differs from the staging test because |
|---|---|---|
| 0 Accounts and preflight | creates the test accounts in Keycloak (random password every run, kept in memory), checks the four tokens, the API, the tools, registers a Crypt4GH key | the realm ships with no human user |
| 1 Prepare the data | generates a bundle with `create_test_bundle.php`, validates it with `fega-cli`, writes the data files into `../sda-inbox/<e-mail>/` | the SDA is a folder, not an SFTP server |
| 2 Uploaded files | the cron job of the API container registers the files, the test waits for them in "My Uploaded Files" | the cron job runs every minute (the test runs it at once) |
| 3 Bundle upload and editing | uploads the zip, edits the study and a sample, deletes a sample (on a scratch study), reads every resource type, checks that the study is private | |
| 4 Policy and submission | health check, policy of the mock DAC portal, submit | |
| 5 Publication | waits until both datasets and the study are published | no DAC decision on a submission: a cron job publishes what is submitted once its release date has come |
| 6 Catalogue and Beacon | dataset in the catalogue, its page lists its files, Beacon (skipped when the image has none) | |
| 7 Access request | opens a request, sends the form, downloads and uploads the DAA, **the DAC approves, then revokes** | the mock DAC portal never decides: the test sends the decision with the token of the `dac-cli` client, as the real DAC portal does |

Steps 3.6 and 7.2b check that a study and an access request belong to their owner, and 7.4 that neither the submitter nor the help desk can decide a request. Not covered: the dataset download (needs
RabbitMQ and the DOA), what the pages look like, and the DAC portal itself.

## Bugs found by this test, and the known-bug mechanism

The first runs found five bugs of the API. They are fixed in `fhdportal-api`, and each has a step of its own that now guards the fix:

| Step | The bug | The fix |
|---|---|---|
| 3.7 | two edits of a study within one second were appended to the same `upload_<YmdHis>.json`, and the second was refused ("Unsupported file format") | one file per edit, with a random suffix (`ResourceEditService::editResource`) |
| 3.8 | an anonymous request for a study was answered with 500 | the exception listener gives a plain `Exception` with a 4xx code its status |
| 3.9 | a user without a role got 200 with `{"error":{"status":401}}` instead of an error status | `getSubmission` answers with the status of the error, as its sibling routes do |
| 3.10 | deleting a sample made the health check report a blocking `deleted_but_linked` error: such a study could not be submitted | only a rejected resource is reported; a deleted one is soft-deleted and ignored, and a live reference to it is caught by the cross-reference check |
| 7.2, 7.2b | the owner of a new access request got 403 on the form `GET` and on the `PATCH`: the portal only knows a request after that first `PATCH`, but checked ownership before | a request the portal does not know yet may be opened; once it is known only its owner (or an administrator) passes, which 7.2b checks |

For a bug that cannot be fixed at once, mark its step `test.fail(true, '<what is wrong>')`, and add a workaround to the scenario if it
blocks the steps after it. The step must then fail, which keeps the run green, and the report lists it under "Known bugs". When the
bug is fixed the step passes, Playwright reports that as a failure, and the run stays red until the mark (and the workaround) is removed.

## What the test needs from the demonstrator

- A realm with the `dac-cli` client and role, and the audience mapper `fhdportal-api-audience` on `fhdportal-sp`, `fhdportal-cli` and
  `dac-cli`, and the C4GH and SSH key mappers on `fhdportal-cli` (the user logins of the test use that client). `init/fhdportal-realm.json`
  has them. Keycloak only imports it into a **new** database: an existing one needs the mappers added by hand, or a reset.
- `KEYCLOAK_ALLOWED_AZP` in `../.env` has to include `dac-cli`.
- The API container mounts `../sda-inbox` and runs `tools/cron_sda.php` and `tools/cron_publish.php`.

## Notes

- Run against an image that has the fixes of `fhdportal-api` listed above (the demonstrator builds the API from its default branch on GitHub):
  steps 3.7 to 3.10 and 7.2 fail on an older one.
- The test creates three accounts (`e2e-submitter`, `e2e-helpdesk`, `e2e-outsider`) in the realm, using the Keycloak admin account
  of `../.env`. `E2E_MANAGE_ACCOUNTS=0` uses existing accounts instead.
- The data files are random bytes, named as in the bundle: the fake SDA only checks name, size and sha256. They stay in `../sda-inbox`.
- The submitter has to make an API call before the files are dropped (step 0.2 does), or the cron job creates a second portal user
  with the same e-mail address.
- `GET /dacs` is rate limited (5 calls a minute): the test calls it once.

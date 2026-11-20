# Screenshots of the README

The images are named `NN-what-they-show.png` after the step they illustrate. When one is retaken, keep its name.

## To take (from one clean run)

Start from a clean demonstrator (`docker compose down && rm -rf fhd-db-data sda-inbox && docker compose up -d`), use **one**
user name and e-mail address throughout (for example `demo.submitter@example.org`), a fixed window width of about 1300 px,
light mode, and crop to the relevant area. The README has an `<!-- TODO screenshot -->` comment at each place.

| File to create | After the step | Shows |
|---|---|---|
| `16-my-uploaded-files.png` | "Put the encrypted files in your inbox" | **My uploaded files** listing the dropped files, with their status and accession (`CHFEGAF…`) |
| `17-policy-dialog.png` | "Choose a policy" | the **Policy** dialog with *Standard Data Access Policy* |
| `18-submit-study.png` | "Submit the study" | the **Submit Study** confirmation, and the study status chip `submitted` |
| `19-dataset-approved.png` | "The DAC approves" | a dataset with the status `approved`, after the cron job |
| `20-admin-dataset-reviews.png` | "The help desk publishes" | **Admin → Dataset Reviews** with *approve…* and *confirm publication* |
| `21-dataset-published.png` | "The help desk publishes" | the dataset `published`, and its catalogue entry with the file list |
| `22-dataset-requests-approved.png` | "The DAC decides" | **Admin → Dataset Requests** after `scripts/dac-decision.sh`: status `approved`, then `rejected` (replaces the former figure 16, which showed buttons that no longer exist) |
| `23-beacon-datasets.png` | "Beacon" | the response of `/api/beacon/datasets` in a browser tab |
| `24-e2e-result.png` | "Test it" | a terminal capture of `npm run e2e` ending in `62 passed, 1 skipped`, and a page of the generated `test-report.md` |
| `25-mailhog-all.png` | "Mails" | MailHog with the three mails of the workflow |
| `26-keycloak-login.png` | "Open the portal" | the Keycloak login page |
| `27-submitter-portal-ready.png` | "Register the keys" | the Submitter portal with **Submit a New Study**, after role and keys |

A 30-second silent screen recording of "Complete the submission" to "The help desk publishes" can replace figures 17 to 21.

## To check against the current interface

| File | What to compare |
|---|---|
| `01-home-submitter-portal.png` | the menu of a logged-in user now has *My uploaded files*, *My Dataset Downloads* and *User manual*: add a second image of it |
| `10-upload-study-result.png` | the dialog's tabs are *Study, Sample, MolecularExperiment, MolecularRun, MolecularAnalysis, Dataset*; show the dataset and sample rows too, not only the study row |
| `13-request-access-button.png`, `14-request-form.png` | the request form is now served by the DAC portal (here: its mock) |

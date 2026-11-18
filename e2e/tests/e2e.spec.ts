// End-to-end scenario of the FHDportal demonstrator, driven through the API: accounts, test data, fake SDA inbox,
// bundle upload and editing, policy, submission, publication, catalogue, access request and the DAC decision.
//
// What differs from a production node, and so from the staging test this one comes from:
//  - the SDA is a folder (sda-inbox/<e-mail>/) read by a cron job of the API container, no SFTP;
//  - there is no DAC decision on a submission: a cron job publishes what is submitted once its release date has come;
//  - the mock DAC portal only answers, it never decides: the test plays the DAC portal for the access request, with
//    the token of the "dac-cli" client, which is how the real DAC portal sends its decision.
import { expect, test } from '@playwright/test'
import fs from 'node:fs'
import path from 'node:path'
import { Api, asList, collectTitles, findDeep, parseNdjson, publicId } from '../src/api'
import { accessToken, claims, forgetTokens } from '../src/auth'
import { Bundle, dropFiles, generateBundle, listInbox, runInApiContainer, validateBundle } from '../src/bundle'
import { cfg, Role } from '../src/config'
import { waitForUploadedFiles } from '../src/files'
import { AccountInfo, ensureAccounts } from '../src/keycloak-admin'
import { poll } from '../src/poll'
import { preflight } from '../src/preflight'
import { deepMerge, fillForm, selectPurpose } from '../src/schema-fill'
import crypto from 'node:crypto'

interface State {
    accounts?: Record<'SUBMITTER' | 'HELPDESK' | 'OUTSIDER', AccountInfo>
    bundle?: Bundle
    studyId?: string
    dataset?: any
    requestId?: string
    requestKey?: string
}

const SIGNED_DAA_IRI = 'https://ontology.swisscustodian.ch/schema/SignedDAA'

const S: State = {}
let api: Api

const attach = (name: string, data: unknown) =>
    test.info().attach(name, {
        body: typeof data === 'string' ? data : JSON.stringify(data, null, 2),
        contentType: typeof data === 'string' ? 'text/plain' : 'application/json'
    })

function need<T>(value: T | undefined, message: string): T {
    if (value === undefined) throw new Error(message)
    return value
}
const bundle = (): Bundle => need(S.bundle, 'no bundle: step 1.1 did not run')
const studyId = (): string => need(S.studyId, 'no study: step 3.1 did not run')
const study = (kind: string) => api.get('SUBMITTER', `/submissions/${studyId()}/${kind}`).then(asList)
const isExtraSample = (s: any) => [s.title, s.properties?.alias, s.properties?.title].includes(bundle().extraSampleAlias)
const requestStatus = (r: any): string => String(r.request_status ?? r.status ?? r.status_type ?? '')
const isAccepted = (r: any) => cfg().requestAccepted.includes(requestStatus(r).toLowerCase())
const requestsFor = (all: any[], dataset: any) => all.filter((r) => [dataset.id, dataset.public_id].some((k) => k && JSON.stringify(r).includes(k)))

// Asks the cron jobs of the API container to run now (they run every minute anyway)
async function cron(job: 'cron_sda' | 'cron_approve'): Promise<void> {
    if (!cfg().triggerCron) return
    const result = await runInApiContainer(['php', `tools/${job}.php`])
    console.log(`${job}: ${result}`)
}

test.describe.configure({ mode: 'serial' })

test.beforeAll(async () => {
    api = await Api.create()
})
test.afterAll(async () => {
    await api?.dispose()
})

test.describe('Phase 0: accounts and preflight', () => {
    test('0.1 the test accounts exist in Keycloak (created when missing)', async () => {
        test.skip(!cfg().manageAccounts, 'E2E_MANAGE_ACCOUNTS=0: the accounts are used as they are')
        S.accounts = await ensureAccounts()
        await attach('accounts.json', S.accounts)
        for (const a of Object.values(S.accounts)) console.log(`0.1 ${a.username} <${a.email}> ${a.created ? 'created' : 'found'}`)
    })

    test('0.2 configuration, credentials and tools are in place', async () => {
        const notes = await preflight(api)
        console.log(notes.join('\n'))
        await attach('preflight.txt', notes.join('\n'))
    })

    test('0.3 the submitter registers a Crypt4GH key (needed for an access request)', async () => {
        const me = claims(await accessToken('SUBMITTER'))
        if (me?.['c4gh-public-key']) {
            console.log('0.3 the submitter already has a Crypt4GH key')
            return
        }
        // a Crypt4GH public key is 32 bytes, in base64 between the BEGIN/END CRYPT4GH PUBLIC KEY lines
        const key = `-----BEGIN CRYPT4GH PUBLIC KEY-----\n${crypto.randomBytes(32).toString('base64')}\n-----END CRYPT4GH PUBLIC KEY-----`
        const res = await api.raw('SUBMITTER', 'POST', `/users/${me.sub}/public-key`, { json: { params: { userKey: key, type: 'c4gh' } } })
        expect(res.status, res.text.slice(0, 400)).toBeLessThan(300)
        forgetTokens() // the key is a claim of the token: log in again
        expect(claims(await accessToken('SUBMITTER'))?.['c4gh-public-key'], 'the new token must carry the key').toBeTruthy()
    })
})

test.describe('Phase 1: prepare the test data', () => {
    test('1.1 generate the bundle with an extra sample and an extra study attribute', async () => {
        S.bundle = await generateBundle()
        await attach('bundle.json', S.bundle)
        console.log(`bundle ${S.bundle.name} (seed ${S.bundle.seed}): ${JSON.stringify(S.bundle.counts)}`)
        expect(fs.existsSync(S.bundle.zip)).toBe(true)
        expect(S.bundle.counts.datasets).toBe(2)
    })

    test('1.2 validate the bundle with fega-cli', async () => {
        await attach('fega-cli.txt', await validateBundle(bundle()))
    })

    test('1.3 put the data files into the inbox of the submitter (fake SDA)', async () => {
        // The portal user must exist before the cron job sees the folder (0.2 made a call as the submitter), or the cron
        // job creates a second user with the same e-mail address.
        const email = cfg().accounts.SUBMITTER.email
        const dropped = dropFiles(bundle(), email)
        console.log(`1.3 ${dropped.written} files written to ${dropped.dir}`)
        expect(listInbox(email)).toEqual(expect.arrayContaining(bundle().fileNames))
    })
})

test.describe('Phase 2: uploaded files', () => {
    test('2.1 the files are listed in "My Uploaded Files"', async () => {
        test.setTimeout(cfg().filesTimeoutMs + 60_000)
        await waitForUploadedFiles(api, bundle(), {
            timeoutMs: cfg().filesTimeoutMs,
            intervalMs: cfg().pollIntervalMs,
            log: (m) => console.log(`2.1 ${m}`),
            beforeAttempt: () => cron('cron_sda')
        })
    })
})

test.describe('Phase 3: bundle upload and editing', () => {
    test('3.1 upload the bundle zip', async () => {
        const b = bundle()
        const res = await api.raw('SUBMITTER', 'POST', '/submissions/upload-study', {
            multipart: { file1: { name: path.basename(b.zip), mimeType: 'application/zip', buffer: fs.readFileSync(b.zip) }, nb_files: '1' },
            timeoutMs: 5 * 60_000
        })
        expect(res.status, res.text.slice(0, 500)).toBe(200)
        const events = parseNdjson(res.text)
        await attach('upload-events.json', events)
        const last = events[events.length - 1]
        expect(last?.type, JSON.stringify(last)).toBe('result')
        expect(last.data?.success, JSON.stringify(last.data).slice(0, 800)).toBe(true)

        const found = asList(await api.get('SUBMITTER', '/submissions')).find(
            (s) => String(s.title ?? s.properties?.title).toLowerCase() === b.studyTitle.toLowerCase()
        )
        expect(found, `no submission titled "${b.studyTitle}"`).toBeTruthy()
        S.studyId = publicId(found)

        // every resource of the bundle was imported (the extra sample included)
        expect(await study('samples')).toHaveLength(b.counts.samples)
        expect(await study('experiments')).toHaveLength(b.counts.experiments)
        expect(await study('runs')).toHaveLength(b.counts.runs)
        expect(await study('analyses')).toHaveLength(b.counts.analyses)
        expect(await study('datasets')).toHaveLength(b.counts.datasets)
    })

    test('3.2 remove the extra study attribute', async () => {
        const tag = bundle().extraAttributeTag
        const before = await api.get('SUBMITTER', `/submissions/${studyId()}`)
        const props = { ...(before.properties ?? before) }
        const attributes: any[] = props.extra_attributes ?? []
        expect(attributes.map((a) => a.tag), 'the bundle must carry the extra attribute').toContain(tag)

        props.extra_attributes = attributes.filter((a) => a.tag !== tag)
        await api.put('SUBMITTER', `/submissions/${studyId()}`, { ...props, id: before.id })

        const after = await api.get('SUBMITTER', `/submissions/${studyId()}`)
        const left: any[] = (after.properties ?? after).extra_attributes ?? []
        expect(left.map((a) => a.tag)).not.toContain(tag)
        expect(left).toHaveLength(attributes.length - 1)
    })

    test('3.3 edit one sample', async () => {
        const sample = (await study('samples')).find((s) => !isExtraSample(s))
        expect(sample, 'no regular sample found').toBeTruthy()
        const description = `E2E edited ${bundle().name}`
        await api.put('SUBMITTER', `/submissions/${studyId()}/samples/${publicId(sample)}`, {
            properties: { ...sample.properties, description },
            sample_type: sample.sample_type ?? 'Sample'
        })
        const updated = (await study('samples')).find((s) => publicId(s) === publicId(sample))
        expect(updated?.properties?.description).toBe(description)
    })

    test('3.4 delete the extra sample', async () => {
        const extra = (await study('samples')).find(isExtraSample)
        expect(extra, `extra sample ${bundle().extraSampleAlias} not found`).toBeTruthy()
        await api.del('SUBMITTER', `/submissions/${studyId()}/samples/${publicId(extra)}`)

        expect(await study('samples')).toHaveLength(bundle().counts.samples - 1)
        expect((await study('samples')).find(isExtraSample)).toBeUndefined()
        expect(await study('runs'), 'deleting the sample must not remove runs').toHaveLength(bundle().counts.runs)
    })

    test('3.5 resources of every type can be read', async () => {
        const s = await api.get('SUBMITTER', `/submissions/${studyId()}`)
        expect(publicId(s)).toBe(studyId())
        const c = bundle().counts
        const expected: Record<string, number> = {
            samples: c.samples - 1,
            experiments: c.experiments,
            runs: c.runs,
            analyses: c.analyses,
            datasets: c.datasets
        }
        for (const [kind, count] of Object.entries(expected)) {
            const items = await study(kind)
            expect(items, kind).toHaveLength(count)
            for (const item of items) expect(publicId(item), `${kind} item without public id`).toBeTruthy()
        }
    })

    test('3.6 the study is private: not for an anonymous caller, not for a user without a role (authorization)', async () => {
        const anonymous = await fetch(`${cfg().apiUrl}/submissions/${studyId()}`)
        expect(anonymous.status, 'an anonymous caller read the draft study').toBeGreaterThanOrEqual(400)
        expect(await anonymous.text(), 'the answer to an anonymous caller must not carry the study').not.toContain(studyId())

        // a logged-in user who owns nothing and has no role of the portal
        const outsider = await api.raw('OUTSIDER', 'GET', `/submissions/${studyId()}`)
        expect(outsider.text, 'the answer to a user without a role must not carry the study').not.toContain(studyId())
        expect(outsider.text, 'the answer to a user without a role must not carry the study').not.toContain(bundle().studyTitle)
        const theirs = await api.raw('OUTSIDER', 'GET', '/submissions')
        expect(JSON.stringify(theirs.body ?? ''), 'the study is listed for a user without a role').not.toContain(studyId())
    })

    test('3.7 two edits within the same second both succeed', async () => {
        // They used to be written to the same upload_<YmdHis>.json, which then held two JSON documents and was refused
        const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms))
        await sleep(1100 - (Date.now() % 1000) + 50) // both calls start early in the same second
        const sample = (await study('samples')).find((s) => !isExtraSample(s))
        expect(sample, 'no regular sample found').toBeTruthy()
        const send = (n: number) =>
            api.raw('SUBMITTER', 'PUT', `/submissions/${studyId()}/samples/${publicId(sample)}`, {
                json: { properties: { ...sample.properties, description: `E2E same second ${n}` }, sample_type: sample.sample_type ?? 'Sample' }
            })
        const answers = await Promise.all([send(1), send(2)])
        expect(answers.map((a) => a.status), answers.map((a) => a.text.slice(0, 120)).join(' | ')).toEqual([200, 200])
    })

    test('3.8 an anonymous request is answered with 401', async () => {
        // it used to be a 500: a plain Exception("Unauthorized", 401) was not given its status
        const anonymous = await fetch(`${cfg().apiUrl}/submissions/${studyId()}`)
        expect(anonymous.status).toBe(401)
    })

    test('3.9 a read refused to a user without a role is answered with 4xx', async () => {
        // it used to be a 200 with {"error":{"message":"Unauthorized","status":401}, "sampleTypes":[], ...} (no study data)
        const outsider = await api.raw('OUTSIDER', 'GET', `/submissions/${studyId()}`)
        expect([401, 403, 404], outsider.text.slice(0, 160)).toContain(outsider.status)
    })

    test('3.10 a study with a deleted sample passes the check', async () => {
        // it used to report every deleted resource as a blocking "is linked to the study but has been deleted"
        const check = await api.get('SUBMITTER', `/submissions/${studyId()}/check`)
        const codes = (check.issues ?? []).map((i: any) => i.code)
        expect(codes, JSON.stringify(check.errors)).not.toContain('deleted_but_linked')
        expect(check.success, JSON.stringify(check.errors)).toBe(true)
    })
})

test.describe('Phase 4: policy and submission', () => {
    test('4.1 check the submission: no blocking problem', async () => {
        const check = await api.get('SUBMITTER', `/submissions/${studyId()}/check`)
        await attach('check.json', check)
        for (const warning of check.warnings ?? []) console.log(`4.1 warning: ${warning}`)
        // Warnings are only recorded (the policies are not set yet); an error would block the submission in 4.3.
        expect(check.success, `blocking problems: ${JSON.stringify(check.errors ?? check)}`).toBe(true)
    })

    test('4.2 attach the test policy to both datasets', async () => {
        const { policyTitle } = cfg()
        // GET /dacs is one of the expensive routes (5 calls a minute): called once
        const dacs = await api.get('SUBMITTER', '/dacs')
        const policy = findDeep(dacs, (o) => o.title === policyTitle && (o.id || o.public_id))
        expect(policy, `policy "${policyTitle}" not offered. Titles seen: ${[...new Set(collectTitles(dacs))].join(' | ')}`).toBeTruthy()
        const policyId = policy.id ?? policy.public_id

        for (const dataset of await study('datasets')) {
            await api.put('SUBMITTER', `/submissions/${studyId()}/datasets/${publicId(dataset)}`, {
                properties: { ...dataset.properties, policy_id: policyId },
                dataset_type: 'Dataset'
            })
        }
        for (const dataset of await study('datasets')) {
            expect(dataset.policy_id ?? dataset.properties?.policy_id, `dataset ${publicId(dataset)}`).toBe(policyId)
        }
    })

    test('4.3 submit the study', async () => {
        await api.patch('SUBMITTER', `/submissions/${studyId()}`, { status_type_id: 'SUB' })
        const after = await api.get('SUBMITTER', `/submissions/${studyId()}`)
        expect(after.status_type_id).toBe('SUB')
    })
})

test.describe('Phase 5: approval and publication', () => {
    const isStatus = (d: any, id: string, name: string) => [d.status_type_id, d.status].some((s) => [id.toLowerCase(), name.toLowerCase()].includes(String(s).toLowerCase()))
    // The review list of the help desk ("Dataset Publication Review"); /datasets is the public catalogue.
    const mine = async () => asList(await api.get('HELPDESK', '/admin/datasets')).filter((d) => d.study_public_id === studyId() || d.study_id === studyId())

    // There is no DAC portal here: a cron job of the API container (init/cron_approve.php) plays it, and approves what is submitted.
    // It never publishes: that is up to an administrator of FHDportal (5.4).
    test('5.1 the cron job plays the DAC portal: both datasets and the study are approved', async () => {
        test.setTimeout(cfg().approvalTimeoutMs + 60_000)
        await poll(
            'both datasets and the study approved',
            async () => {
                await cron('cron_approve')
                const datasets = await study('datasets')
                const states = datasets.map((d) => d.status_type_id ?? d.status)
                const studyStatus = (await api.get('SUBMITTER', `/submissions/${studyId()}`)).status_type_id
                return datasets.length === 2 && states.every((s) => String(s).toUpperCase() === 'APR') && studyStatus === 'APR'
                    ? { done: true as const, value: states }
                    : { done: false as const, note: `datasets ${JSON.stringify(states)}, study ${studyStatus}` }
            },
            { timeoutMs: cfg().approvalTimeoutMs, intervalMs: cfg().pollIntervalMs }
        )
    })

    test('5.2 an approved dataset is not published, and the submitter cannot publish it', async () => {
        for (const d of await study('datasets')) expect(d.status_type_id, `dataset ${publicId(d)}`).toBe('APR')
        // nobody is published yet: the catalogue does not list them
        const catalogue = asList(await api.get('SUBMITTER', '/datasets'))
        for (const d of await study('datasets')) expect(catalogue.some((c) => c.public_id === publicId(d)), `${publicId(d)} is in the catalogue`).toBe(false)

        // the decision to publish is the help desk's
        const [first] = await study('datasets')
        const res = await api.raw('SUBMITTER', 'PATCH', `/submissions/${studyId()}/datasets/${publicId(first)}`, { json: { status_type_id: 'PUB' } })
        const after = (await study('datasets')).find((d) => publicId(d) === publicId(first))
        expect(after.status_type_id, `the submitter published a dataset: HTTP ${res.status} ${res.text.slice(0, 120)}`).toBe('APR')
    })

    test('5.3 the help desk sees both approved datasets in the review list', async () => {
        const datasets = await mine()
        await attach('review-list.json', datasets.map((d: any) => ({ id: d.public_id, status: d.status, status_type_id: d.status_type_id, released_date: d.released_date })))
        expect(datasets, 'the datasets of the study in the help desk review list').toHaveLength(2)
        for (const d of datasets) expect(isStatus(d, 'APR', 'approved'), `dataset ${d.public_id}: ${d.status_type_id} / ${d.status}`).toBe(true)
    })

    test('5.4 the help desk publishes both datasets', async () => {
        for (const d of await mine()) {
            await api.patch('HELPDESK', `/submissions/${d.study_id}/datasets/${d.id}`, { status_type_id: 'PUB' })
        }
        const states = (await study('datasets')).map((d) => d.status_type_id)
        expect(states, 'both datasets are published').toEqual(['PUB', 'PUB'])
    })

    test('5.5 the study is published too', async () => {
        const after = await api.get('SUBMITTER', `/submissions/${studyId()}`)
        expect(after.status_type_id).toBe('PUB')
    })
})

test.describe('Phase 6: catalogue and Beacon', () => {
    test('6.1 a published dataset is in the catalogue', async () => {
        test.setTimeout(cfg().catalogueTimeoutMs + 60_000)
        const [first] = await study('datasets')
        S.dataset = first
        const id = publicId(first)
        await poll(
            'published dataset in the catalogue',
            async () => {
                const catalogue = asList(await api.get('SUBMITTER', '/datasets'))
                return catalogue.some((d) => d.public_id === id)
                    ? { done: true as const, value: true }
                    : { done: false as const, note: `${catalogue.length} datasets in the catalogue, not ${id}` }
            },
            { timeoutMs: cfg().catalogueTimeoutMs, intervalMs: cfg().pollIntervalMs }
        )
    })

    test('6.2 the dataset page shows its files', async () => {
        const dataset = await api.get('SUBMITTER', `/datasets/${publicId(S.dataset)}`)
        await attach('dataset.json', dataset)
        expect(dataset.study_public_id, JSON.stringify(dataset).slice(0, 300)).toBe(studyId())
        expect(asList(dataset.files).length, 'the dataset must list its data files').toBeGreaterThan(0)
    })

    test('6.3 Beacon lists the published dataset (needs a build that has Beacon)', async () => {
        test.setTimeout(cfg().beaconTimeoutMs + 60_000)
        const info = await fetch(`${cfg().apiUrl}/beacon/info`)
        test.skip(info.status === 404, 'this API build has no Beacon (the image is built from the default branch of fhdportal-api)')
        expect(info.status).toBe(200)

        // The Beacon keeps its model of the published datasets for 5 minutes (BeaconRepository::CACHE_SECONDS): a dataset published
        // a moment ago shows up within that time. Drop the model when the API container can be reached, else wait for it.
        if (cfg().triggerCron) {
            console.log(`6.3 beacon cache: ${await runInApiContainer(['php', 'bin/console', 'cache:pool:delete', 'cache.app', 'beacon_model_v1'])}`)
        }
        const id = publicId(S.dataset)
        // public: no token
        const body: any = await poll(
            'published dataset in the Beacon',
            async () => {
                const res = await fetch(`${cfg().apiUrl}/beacon/datasets/${id}`)
                if (res.status !== 200) throw new Error(`GET /beacon/datasets/${id} -> HTTP ${res.status}`)
                const answer: any = await res.json()
                return answer.responseSummary?.exists
                    ? { done: true as const, value: answer }
                    : { done: false as const, note: `not listed yet: ${JSON.stringify(answer.responseSummary)}` }
            },
            { timeoutMs: cfg().beaconTimeoutMs, intervalMs: 10_000 }
        )
        await attach('beacon-dataset.json', body)
        expect(JSON.stringify(body)).toContain(id)
        // a dataset that does not exist answers with an empty result set, not an error
        const none = await fetch(`${cfg().apiUrl}/beacon/datasets/CHFEGAD99999999999`)
        expect(none.status).toBe(200)
        expect(((await none.json()) as any).responseSummary?.exists).toBe(false)
    })
})

test.describe('Phase 7: access request and the DAC decision', () => {
    test('7.1 request access: the request is opened at the DAC portal', async () => {
        const dataset = S.dataset
        const failures: string[] = []
        for (const key of [dataset.id, dataset.public_id].filter(Boolean)) {
            const created = await api.raw('SUBMITTER', 'POST', '/dacs/requests', { json: { datasetIDs: [key] } })
            if (created.status >= 200 && created.status < 300 && created.body?.id) {
                S.requestId = created.body.id
                S.requestKey = key
                break
            }
            failures.push(`datasetIDs=[${key}] -> HTTP ${created.status}: ${created.text.slice(0, 200)}`)
        }
        expect(S.requestId, failures.join('\n')).toBeTruthy()
    })

    test('7.2 the requester opens the form and sends it', async () => {
        // The owner of a new request used to get 403 "Forbidden" here and on the PATCH: the portal only knows a request after
        // that first PATCH, but checked that the caller owns it before.
        const form = (await api.get('SUBMITTER', `/dacs/requests/${S.requestId}/form`)).jsonForms
        const overrides = cfg().requestFormOverrides ? JSON.parse(cfg().requestFormOverrides!) : {}
        const filled = fillForm(form.schema, form.initialValues ?? form.data ?? {})
        const purpose = selectPurpose(form.schema, filled)
        console.log(`7.2 purpose ticked: ${purpose ?? 'none found in the form (set E2E_REQUEST_FORM_JSON if the request is refused)'}`)
        const formValues = deepMerge(filled, overrides)
        await attach('request-form-schema.json', form.schema)
        await attach('request-form-values.json', formValues)
        await api.patch('SUBMITTER', `/dacs/requests/${S.requestId}`, {
            formValues,
            attachments: [],
            attachmentFiles: [],
            status: 'pending',
            dataset_id: S.requestKey
        })
    })

    test('7.2b somebody else cannot open or send the request once it is registered (authorization)', async () => {
        // the help desk is an administrator and may; a user who owns nothing may not
        for (const method of ['GET', 'PATCH'] as const) {
            const path = method === 'GET' ? `/dacs/requests/${S.requestId}/form` : `/dacs/requests/${S.requestId}`
            const res = await api.raw('OUTSIDER', method, path, method === 'PATCH' ? { json: { formValues: {}, attachments: [], attachmentFiles: [], status: 'pending', dataset_id: S.requestKey } } : {})
            expect(res.status, `${method} ${path} by a user who does not own the request`).toBe(403)
        }
    })

    test('7.3 download the DAA and upload it signed', async () => {
        const daa = await api.raw('SUBMITTER', 'GET', `/dacs/requests/${S.requestId}/daa`)
        expect(daa.status, daa.text.slice(0, 300)).toBe(200)
        expect(daa.buffer.subarray(0, 5).toString('latin1'), 'the DAA must be a PDF').toBe('%PDF-')
        await test.info().attach('daa.pdf', { body: daa.buffer, contentType: 'application/pdf' })

        // Signing is a person's job: the test uploads the downloaded agreement as the signed one.
        await api.patch('SUBMITTER', `/dacs/requests/${S.requestId}`, {
            attachmentFiles: [
                {
                    iri: SIGNED_DAA_IRI,
                    fileName: `signed-daa-${bundle().name}.pdf`,
                    mimeType: 'application/pdf',
                    fileContent: daa.buffer.toString('base64')
                }
            ]
        })

        const request = await poll(
            'request listed for the submitter',
            async () => {
                const all = asList(await api.get('SUBMITTER', '/requests'))
                const found = requestsFor(all, S.dataset)[0]
                return found ? { done: true as const, value: found } : { done: false as const, note: `${all.length} requests, none for ${publicId(S.dataset)}` }
            },
            { timeoutMs: 60_000, intervalMs: 3000 }
        )
        await attach('request.json', request)
        expect(isAccepted(request), `status already ${requestStatus(request)}`).toBe(false)
        S.requestId = request.request_id ?? request.id ?? S.requestId
    })

    test('7.4 only the DAC client can decide a request (authorization)', async () => {
        // The portal has no code path that approves a request on its own authority: the submitter and the help desk are refused
        for (const role of ['SUBMITTER', 'HELPDESK'] as Role[]) {
            const res = await api.raw(role, 'PATCH', `/requests/${S.requestId}`, { json: { request_status: 'APR' } })
            expect(res.status, `${role} must not decide a request`).toBe(401)
        }
        const all = requestsFor(asList(await api.get('SUBMITTER', '/requests')), S.dataset)
        expect(all.some(isAccepted), 'the refused calls must not change the status').toBe(false)
    })

    test('7.5 the DAC approves the request (the decision callback)', async () => {
        const res = await api.raw('DAC', 'PATCH', `/requests/${S.requestId}`, { json: { request_status: 'APR' } })
        expect(res.status, res.text.slice(0, 400)).toBe(200)
    })

    test('7.6 the request is approved for the submitter and the help desk', async () => {
        const views: Array<[Role, string]> = [
            ['SUBMITTER', '/requests'],
            ['HELPDESK', '/admin/requests']
        ]
        for (const [role, path] of views) {
            const all = requestsFor(asList(await api.get(role, path)), S.dataset)
            expect(all.some(isAccepted), `${role} ${path}: statuses ${JSON.stringify(all.map(requestStatus))}`).toBe(true)
        }
    })

    test('7.7 the DAC revokes the request', async () => {
        const res = await api.raw('DAC', 'PATCH', `/requests/${S.requestId}`, { json: { request_status: 'REJ' } })
        expect(res.status, res.text.slice(0, 400)).toBe(200)
        const all = requestsFor(asList(await api.get('SUBMITTER', '/requests')), S.dataset)
        expect(all.some(isAccepted), `statuses ${JSON.stringify(all.map(requestStatus))}`).toBe(false)
        expect(all.map((r) => requestStatus(r).toLowerCase()).some((st) => ['rej', 'rejected'].includes(st)), `statuses ${JSON.stringify(all.map(requestStatus))}`).toBe(true)
    })

    test('7.8 an unknown status is refused', async () => {
        const res = await api.raw('DAC', 'PATCH', `/requests/${S.requestId}`, { json: { request_status: 'NOPE' } })
        expect(res.status).toBeGreaterThanOrEqual(400)
    })

    test.fixme('7.9 download the dataset (needs RabbitMQ and the DOA: not part of the demonstrator)', async () => {})
})

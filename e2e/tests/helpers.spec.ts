// Unit tests of the helpers of the suite: they need no running demonstrator (npm run unit).
import { expect, test } from '@playwright/test'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { asList, collectTitles, findDeep, parseNdjson } from '../src/api'
import { dropFiles, listInbox, splitCommand } from '../src/bundle'
import { cfg, checkedUrl } from '../src/config'
import { waitForUploadedFiles } from '../src/files'
import { poll } from '../src/poll'
import { buildMarkdown, StepResult } from '../src/report'
import { deepMerge, fillForm, selectPurpose } from '../src/schema-fill'

test.describe('helpers', () => {
    test('fillForm fills required fields, keeps existing values and applies overrides', () => {
        const schema = {
            type: 'object',
            required: ['title', 'agree', 'kind', 'details', 'tags'],
            properties: {
                title: { type: 'string' },
                agree: { type: 'boolean' },
                kind: { type: 'string', enum: ['research', 'clinical'] },
                optional: { type: 'string' },
                details: { type: 'object', required: ['summary'], properties: { summary: { type: 'string' }, note: { type: 'string' } } },
                tags: { type: 'array', minItems: 1, items: { type: 'string' } }
            }
        }
        const values = fillForm(schema, { title: 'kept' }, { details: { note: 'forced' } })
        expect(values.title).toBe('kept')
        expect(values.agree).toBe(true)
        expect(values.kind).toBe('research')
        expect(values.optional).toBeUndefined()
        expect(values.details).toEqual({ summary: 'E2E test summary', note: 'forced' })
        expect(values.tags).toHaveLength(1)
    })

    test('selectPurpose ticks the first checkbox under a purpose field', () => {
        const schema = {
            type: 'object',
            properties: {
                title: { type: 'string' },
                consent: { type: 'boolean' },
                purposes: { type: 'object', properties: { nonCommercialPurpose: { type: 'boolean' }, nonCommercialResearch: { type: 'boolean' } } }
            }
        }
        const values: any = { title: 'x' }
        expect(selectPurpose(schema, values)).toBe('purposes.nonCommercialPurpose')
        expect(values).toEqual({ title: 'x', purposes: { nonCommercialPurpose: true } })
        expect(selectPurpose({ type: 'object', properties: { title: { type: 'string' } } }, {})).toBeUndefined()
    })

    test('deepMerge merges objects and replaces arrays', () => {
        expect(deepMerge({ a: { b: 1, c: 2 }, l: [1] }, { a: { c: 3 }, l: [2, 3] })).toEqual({ a: { b: 1, c: 3 }, l: [2, 3] })
    })

    test('asList understands arrays, wrapped rows and keyed objects', () => {
        expect(asList([1, 2])).toEqual([1, 2])
        expect(asList({ data: [1], page: {} })).toEqual([1])
        expect(asList({ a: { x: 1 }, b: { x: 2 } })).toEqual([{ x: 1 }, { x: 2 }])
        expect(asList(undefined)).toEqual([])
    })

    test('findDeep and collectTitles search nested answers', () => {
        const answer = { dacs: [{ policies: [{ id: 'p1', title: 'A' }, { id: 'p2', title: 'B' }] }] }
        expect(findDeep(answer, (o) => o.title === 'B')?.id).toBe('p2')
        expect(findDeep(answer, (o) => o.title === 'C')).toBeUndefined()
        expect(collectTitles(answer)).toEqual(['A', 'B'])
    })

    test('parseNdjson skips blank lines', () => {
        expect(parseNdjson('{"a":1}\n\n{"b":2}\n')).toEqual([{ a: 1 }, { b: 2 }])
    })

    test('checkedUrl accepts http(s) URLs and explains a doubled scheme', () => {
        expect(checkedUrl('X', 'https://login.example.org/realms/r/protocol/openid-connect/token')).toContain('login.example.org')
        expect(() => checkedUrl('X', 'https://https://login.example.org/token')).toThrow(/scheme written twice/)
        expect(() => checkedUrl('X', 'login.example.org/token')).toThrow(/not a valid URL/)
        expect(() => checkedUrl('X', 'ftp://login.example.org')).toThrow(/not a usable/)
    })

    test('splitCommand allows a command line for the CLI', () => {
        expect(splitCommand('fega-cli')).toEqual(['fega-cli', []])
        expect(splitCommand('php /x/bin/fega.phar')).toEqual(['php', ['/x/bin/fega.phar']])
    })

    test('poll returns the value once it is ready', async () => {
        let calls = 0
        const value = await poll(
            'ready',
            async () => (++calls < 3 ? { done: false as const, note: `call ${calls}` } : { done: true as const, value: calls }),
            { timeoutMs: 1000, intervalMs: 10 }
        )
        expect(value).toBe(3)
    })

    test('poll times out with the last observation', async () => {
        await expect(poll('never', async () => ({ done: false as const, note: 'still pending' }), { timeoutMs: 50, intervalMs: 20 })).rejects.toThrow(
            /waiting for: never\. Last observation: still pending/
        )
    })
})

test.describe('configuration', () => {
    const saved = { ...process.env }
    test.afterEach(() => {
        for (const k of Object.keys(process.env)) if (!(k in saved)) delete process.env[k]
        Object.assign(process.env, saved)
    })

    test('a stock demonstrator needs no setting: the defaults point at it', () => {
        for (const k of Object.keys(process.env)) if (k.startsWith('E2E_')) delete process.env[k]
        const c = cfg()
        expect(c.apiUrl).toBe('http://localhost:5173/api')
        expect(c.keycloak.tokenUrl).toMatch(/\/realms\/[^/]+\/protocol\/openid-connect\/token$/)
        expect(c.policyTitle).toBe('Standard Data Access Policy')
        expect(c.sdaInbox).toMatch(/sda-inbox$/)
        expect(c.accounts.SUBMITTER.email).toBe('e2e-submitter@example.org')
    })

    test('settings override the defaults, and a trailing slash is dropped', () => {
        process.env.E2E_API_URL = 'https://portal.example.org/api/'
        process.env.E2E_SUBMITTER_USERNAME = 'someone'
        process.env.E2E_TRIGGER_CRON = '0'
        const c = cfg()
        expect(c.apiUrl).toBe('https://portal.example.org/api')
        expect(c.accounts.SUBMITTER.username).toBe('someone')
        expect(c.triggerCron).toBe(false)
    })

    test('a bad URL is reported with its name', () => {
        process.env.E2E_API_URL = 'https://https://portal.example.org/api'
        expect(() => cfg()).toThrow(/E2E_API_URL/)
    })
})

test.describe('waitForUploadedFiles', () => {
    const bundle = { name: 'B1', fileNames: ['B1-a.1.fastq.gz.c4gh', 'B1-b.1.fastq.gz.c4gh'] }
    const fake = (answers: Array<{ status: number; text: string }>) => {
        const calls: any[] = []
        return {
            calls,
            raw: async (_role: any, _method: any, _path: any, opts: any) => {
                calls.push(opts?.query)
                return { ...answers[Math.min(calls.length - 1, answers.length - 1)], body: undefined }
            }
        }
    }
    const opts = { timeoutMs: 200, intervalMs: 10 }

    test('returns once the files are listed, with or without the .c4gh suffix, nudging the SDA before each look', async () => {
        const api = fake([
            { status: 200, text: '{"data":[]}' },
            { status: 200, text: '{"data":[{"title":"B1-a.1.fastq.gz"}]}' },
            { status: 200, text: '{"data":[{"title":"B1-a.1.fastq.gz.c4gh"},{"title":"B1-b.1.fastq.gz"}]}' }
        ])
        let nudges = 0
        await waitForUploadedFiles(api as any, bundle, { ...opts, beforeAttempt: async () => void nudges++ })
        expect(api.calls).toHaveLength(3)
        expect(nudges).toBe(3)
        expect(api.calls[0]).toMatchObject({ search: 'B1', by: 200 })
    })

    test('fails at once on an HTTP error', async () => {
        const api = fake([{ status: 401, text: 'Unauthorized' }])
        await expect(waitForUploadedFiles(api as any, bundle, opts)).rejects.toThrow(/HTTP 401/)
    })

    test('on timeout shows what the account can see without the filter', async () => {
        const api = fake([{ status: 200, text: '{"total":0,"data":[]}' }])
        await expect(waitForUploadedFiles(api as any, bundle, opts)).rejects.toThrow(
            /Timed out.*2 of 2 files not listed yet[\s\S]*Without the search filter, this account sees \(HTTP 200\): \{"total":0/
        )
    })
})

test.describe('buildMarkdown', () => {
    const step = (id: string, status: StepResult['status'], extra: Partial<StepResult> = {}): StepResult => ({
        id,
        title: `${id} step`,
        status,
        durationMs: 1000,
        evidence: [],
        ...extra
    })
    const meta = { tester: 'Ada', startedAt: '2026-11-18 10:00:00', target: 'http://localhost:5173/api', htmlReport: '../../html/index.html' }
    const all = (status: StepResult['status']) => ['0.1', '1.1', '2.1', '3.1', '4.1', '5.1', '6.1', '7.1-7.2', '7.5', '8.1'].map((id) => step(id, status))

    test('a green run is PASSED, with the header fields and the evidence', () => {
        const md = buildMarkdown(
            [...all('passed').filter((s) => s.id !== '4.1'), step('4.1', 'passed', { note: '2 warnings recorded', evidence: [{ name: 'check.json', file: 'evidence/4.1-check.json' }] }), step('7.9', 'skipped', { knownIssue: true })],
            { ...meta, commit: 'abc123', bundle: { name: 'DEMO-E2E-1', seed: '42' } }
        )
        expect(md).toContain('| Commit / version under test | abc123 |')
        expect(md).toContain('| Bundle name and seed | DEMO-E2E-1 (seed 42) |')
        expect(md).toContain('Result: **PASSED**')
        expect(md).toContain('| 4 Policy and submission | PASS | [check.json](evidence/4.1-check.json) | 4.1: 2 warnings recorded |')
        expect(md).toContain('7.9 skipped: known issue')
    })

    test('a failed step makes the run FAILED and the following steps "not run"', () => {
        const steps = all('passed').map((s) => (s.id === '4.1' ? step('4.1', 'failed', { error: '\u001b[31mblocking problems: ["x"]\u001b[39m' }) : /^[567]/.test(s.id) ? { ...s, status: 'skipped' as const } : s))
        const md = buildMarkdown(steps, meta)
        expect(md).toContain('**FAILED (step 4.1)**')
        expect(md).toContain('| 4 Policy and submission | FAIL |')
        expect(md).toContain('4.1 failed: blocking problems: ["x"]')
        expect(md).toContain('| 6 Catalogue and Beacon | not run |')
    })

    test('a step that fails as expected is listed as a known bug and does not fail the run', () => {
        const md = buildMarkdown(
            [...all('passed'), step('3.7', 'knownBug', { bugNote: 'editResource appends every edit of a second to one file' })],
            meta
        )
        expect(md).toContain('Result: **PASSED**')
        expect(md).toContain('3.7 known bug (still present)')
        expect(md).toContain('- **3.7** editResource appends every edit of a second to one file')
    })

    test('a skip decided by the test keeps its reason, a partial run is INCOMPLETE', () => {
        const md = buildMarkdown([step('0.1', 'passed'), step('6.3', 'skipped', { skipReason: 'this API build has no Beacon' })], meta)
        expect(md).toContain('6.3 skipped: this API build has no Beacon')
        expect(md).toContain('**INCOMPLETE (some steps did not run)**')
    })
})

test.describe('the inbox of the fake SDA', () => {
    test('files are written under the e-mail address of the user, with the names of the bundle', async () => {
        const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'e2e-inbox-'))
        const previous = process.env.E2E_SDA_INBOX
        process.env.E2E_SDA_INBOX = dir
        try {
            const bundle: any = { fileNames: ['B-1.fastq.gz.c4gh', 'B-2.fastq.gz.c4gh'] }
            const dropped = dropFiles(bundle, 'someone@example.org')
            expect(dropped.written).toBe(2)
            expect(dropped.dir).toBe(path.join(dir, 'someone@example.org'))
            expect(listInbox('someone@example.org').sort()).toEqual(bundle.fileNames)
            expect(listInbox('nobody@example.org')).toEqual([])
            // the files differ, as the cron job tells them apart by their sha256
            const [a, b] = bundle.fileNames.map((f: string) => fs.readFileSync(path.join(dropped.dir, f)).toString('hex'))
            expect(a).not.toBe(b)
        } finally {
            if (previous === undefined) delete process.env.E2E_SDA_INBOX
            else process.env.E2E_SDA_INBOX = previous
            fs.rmSync(dir, { recursive: true, force: true })
        }
    })
})

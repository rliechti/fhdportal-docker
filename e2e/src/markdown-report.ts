import { execSync } from 'node:child_process'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import type { FullConfig, FullResult, Reporter, TestCase, TestResult } from '@playwright/test/reporter'
import { cfg } from './config'
import { buildMarkdown, StepResult, StepStatus } from './report'

// Writes the test report after every run: <results>/reports/<bundle>/test-report.md plus the evidence files
// (attachments) next to it.
export default class MarkdownReporter implements Reporter {
    private entries: Array<{ test: TestCase; result: TestResult }> = []
    private started = new Date()
    private resultsDir: string

    constructor(options: { resultsDir?: string } = {}) {
        this.resultsDir = path.resolve(options.resultsDir ?? 'results')
    }

    onBegin(_config: FullConfig) {
        this.started = new Date()
    }

    onTestEnd(test: TestCase, result: TestResult) {
        this.entries.push({ test, result })
    }

    async onEnd(_result: FullResult) {
        const steps = this.entries.filter((e) => /^\d+\.\d/.test(e.test.title))
        if (!steps.length) return // the run holds no step of the scenario (e.g. only the helper tests)

        const stamp = this.started.toISOString().slice(2, 19).replace(/[-:]/g, '').replace('T', '-')
        const bundle = this.readBundle(steps)
        const dir = path.join(this.resultsDir, 'reports', bundle?.name ?? `run-${stamp}`)
        const evidenceDir = path.join(dir, 'evidence')
        fs.mkdirSync(evidenceDir, { recursive: true })

        const results: StepResult[] = steps.map(({ test, result }) => {
            const id = test.title.match(/^(\d+\.\d+[a-z]?(?:-\d+\.\d+[a-z]?)?)/)![1]
            const evidence = result.attachments
                .filter((a) => (a.body || a.path) && a.name !== 'error-context')
                .map((a) => {
                    const file = `evidence/${id}-${a.name}`.replace(/[^\w./-]/g, '_')
                    fs.writeFileSync(path.join(dir, file), a.body ?? fs.readFileSync(a.path!))
                    return { name: a.name, file }
                })
            const skip = test.annotations.find((a) => a.type === 'skip' && a.description)
            const bug = test.annotations.find((a) => a.type === 'fail')
            let status = (result.status === 'skipped' || test.outcome() === 'skipped' ? 'skipped' : result.status) as StepStatus
            let error = result.errors.map((e) => e.message ?? '').join('\n') || undefined
            if (bug && status === 'failed') status = 'knownBug' // fails as expected
            else if (bug && status === 'passed') {
                // passes although it is marked as failing: the bug seems to be fixed
                status = 'failed'
                error = `expected to fail (${bug.description ?? 'known bug'}) but passed: the bug seems fixed, remove the test.fail() mark and the workaround`
            }
            return {
                id,
                title: test.title,
                status,
                bugNote: bug?.description,
                durationMs: result.duration,
                error,
                skipReason: skip?.description,
                knownIssue: test.annotations.some((a) => a.type === 'fixme'),
                note: this.noteFor(id, result),
                evidence
            }
        })

        const markdown = buildMarkdown(results, {
            commit: process.env.E2E_COMMIT ?? this.gitCommit(),
            tester: process.env.E2E_TESTER ?? this.git('config user.name') ?? os.userInfo().username,
            startedAt: this.started.toLocaleString('sv-SE'),
            target: process.env.E2E_API_URL ?? this.configuredApiUrl(),
            bundle,
            htmlReport: path.relative(dir, path.join(this.resultsDir, 'html', 'index.html'))
        })
        const file = path.join(dir, 'test-report.md')
        fs.writeFileSync(file, markdown)
        console.log(`\nTest report: ${path.relative(process.cwd(), file)}`)
    }

    printsToStdio() {
        return false
    }

    private configuredApiUrl(): string {
        try {
            return `${cfg().apiUrl} (from ../.env)`
        } catch {
            return 'http://localhost:5173/api (default)'
        }
    }

    private readBundle(steps: Array<{ test: TestCase; result: TestResult }>) {
        const body = steps.flatMap((e) => e.result.attachments).find((a) => a.name === 'bundle.json')?.body
        try {
            const bundle = JSON.parse(body?.toString('utf8') ?? '')
            return { name: String(bundle.name), seed: String(bundle.seed) }
        } catch {
            return undefined
        }
    }

    private noteFor(id: string, result: TestResult): string | undefined {
        if (id !== '4.1') return undefined
        try {
            const check = JSON.parse(result.attachments.find((a) => a.name === 'check.json')?.body?.toString('utf8') ?? '')
            const n = (check.warnings ?? []).length
            return `${n} warning${n === 1 ? '' : 's'} recorded (check.json)`
        } catch {
            return undefined
        }
    }

    // The commit of the demonstrator repository (the folder above e2e)
    private gitCommit(): string | undefined {
        return this.git('rev-parse --short HEAD', path.resolve(__dirname, '..', '..'))
    }

    private git(args: string, cwd?: string): string | undefined {
        try {
            return execSync(`git ${args}`, { cwd, stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim() || undefined
        } catch {
            return undefined
        }
    }
}

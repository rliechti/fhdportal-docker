// Builds the test report of a run from the results of the suite.

// knownBug: a step marked test.fail() that fails as expected, i.e. a bug of the product that is still there
export type StepStatus = 'passed' | 'failed' | 'timedOut' | 'interrupted' | 'skipped' | 'knownBug'

export interface StepResult {
    id: string // "3.4", or "7.1-7.2"
    title: string
    status: StepStatus
    durationMs: number
    error?: string
    skipReason?: string // a skip decided by the test itself, with its reason
    knownIssue?: boolean // test.fixme: left out of the verdict
    bugNote?: string // for a knownBug: what the bug is
    note?: string
    evidence: Array<{ name: string; file: string }>
}

export interface ReportMeta {
    commit?: string
    tester: string
    startedAt: string
    target: string
    bundle?: { name: string; seed: string }
    htmlReport: string
}

export const GROUPS: Array<{ label: string; match: RegExp }> = [
    { label: '0 Accounts and preflight', match: /^0\./ },
    { label: '1 Prepare the data', match: /^1\./ },
    { label: '2 Uploaded files (fake SDA)', match: /^2\./ },
    { label: '3 Bundle upload and editing', match: /^3\./ },
    { label: '4 Policy and submission', match: /^4\./ },
    { label: '5 Publication', match: /^5\./ },
    { label: '6 Catalogue and Beacon', match: /^6\./ },
    { label: '7 Access request and DAC decision', match: /^7\./ }
]

const FAILED: StepStatus[] = ['failed', 'timedOut', 'interrupted']
const cell = (text: string) => text.replace(/\|/g, '\\|').replace(/\s*\n\s*/g, ' ').trim()
const firstLines = (text: string, max = 260) => {
    const flat = text.replace(/\x1b\[[0-9;]*m/g, '').split('\n').map((l) => l.trim()).filter(Boolean).slice(0, 3).join(' ')
    return flat.length > max ? `${flat.slice(0, max)}...` : flat
}

interface Row {
    label: string
    result: string
    evidence: string
    comment: string
    failedIds: string[]
    complete: boolean
}

function row(group: (typeof GROUPS)[number], steps: StepResult[]): Row {
    const mine = steps.filter((s) => group.match.test(s.id))
    const counted = mine.filter((s) => !s.knownIssue)
    const known = mine.filter((s) => s.knownIssue)
    const comments: string[] = []

    const failed = counted.filter((s) => FAILED.includes(s.status))
    const notRun = counted.filter((s) => s.status === 'skipped' && !s.skipReason)
    const skipped = counted.filter((s) => s.status === 'skipped' && s.skipReason)

    let result: string
    if (!counted.length) result = 'not run'
    else if (failed.length) result = 'FAIL'
    else if (notRun.length) result = 'not run'
    else if (skipped.length === counted.length) result = 'skipped'
    else result = 'PASS'

    for (const s of failed) comments.push(`${s.id} failed: ${firstLines(s.error ?? 'no message')}`)
    for (const s of counted.filter((x) => x.status === 'knownBug')) comments.push(`${s.id} known bug (still present)`)
    if (notRun.length && !failed.length) comments.push(`${notRun.map((s) => s.id).join(', ')} not run (an earlier step failed or the run was partial)`)
    for (const s of skipped) comments.push(`${s.id} skipped: ${s.skipReason}`)
    for (const s of known) comments.push(`${s.id} skipped: known issue`)
    for (const s of mine) if (s.note) comments.push(`${s.id}: ${s.note}`)

    const files = mine.flatMap((s) => s.evidence.map((e) => `[${e.name}](${e.file})`))
    return {
        label: group.label,
        result,
        evidence: files.join(', '),
        comment: comments.join(' / '),
        failedIds: failed.map((s) => s.id),
        complete: result === 'PASS' || result === 'skipped'
    }
}

export function buildMarkdown(steps: StepResult[], meta: ReportMeta): string {
    const rows = GROUPS.map((g) => row(g, steps))
    const failedIds = rows.flatMap((r) => r.failedIds)
    const verdict = failedIds.length
        ? `FAILED (step${failedIds.length > 1 ? 's' : ''} ${failedIds.join(', ')})`
        : rows.every((r) => r.complete)
          ? 'PASSED'
          : 'INCOMPLETE (some steps did not run)'

    const bugs = steps.filter((s) => s.status === 'knownBug')
    return [
        '# Test report: FHDportal demonstrator end-to-end test',
        '',
        '| Field | Value |',
        '|---|---|',
        `| Commit / version under test | ${cell(meta.commit ?? '')} |`,
        `| Bundle name and seed | ${meta.bundle ? `${meta.bundle.name} (seed ${meta.bundle.seed})` : ''} |`,
        `| Tester / date | ${cell(meta.tester)} / ${meta.startedAt} |`,
        `| Target | ${cell(meta.target)} |`,
        `| Report of the run | [HTML report](${meta.htmlReport}) |`,
        '',
        `Result: **${verdict}**`,
        '',
        '| Step | Result | Evidence | Comment |',
        '|---|---|---|---|',
        ...rows.map((r) => `| ${cell(r.label)} | ${r.result} | ${r.evidence} | ${cell(r.comment)} |`),
        '',
        ...(bugs.length
            ? [
                  `Known bugs of the product that these steps still show (${bugs.length}). Each is a step marked \`test.fail()\`: when the bug is fixed the step`,
                  'passes, which fails the run until the mark (and the workaround it comes with) is removed.',
                  '',
                  ...bugs.map((b) => `- **${b.id}** ${cell(b.bugNote ?? b.title)}`),
                  ''
              ]
            : [])
    ].join('\n')
}

import { Api } from './api'
import { poll } from './poll'

// "My Uploaded Files": waits until every file of the bundle is listed for the submitter.
// Every file name starts with the bundle name, so the API can filter on it (one page of up to 200 rows).
// The row layout is not relied upon: a file counts as listed when its name appears in the answer,
// with or without the .c4gh suffix. `beforeAttempt` lets the caller nudge the fake SDA (run its cron job).
export async function waitForUploadedFiles(
    api: Pick<Api, 'raw'>,
    bundle: { name: string; fileNames: string[] },
    opts: { timeoutMs: number; intervalMs: number; log?: (message: string) => void; beforeAttempt?: () => Promise<void> }
): Promise<void> {
    const started = Date.now()
    const total = bundle.fileNames.length
    try {
        await poll(
            'all uploaded files listed',
            async () => {
                await opts.beforeAttempt?.()
                const res = await api.raw('SUBMITTER', 'GET', '/files', { query: { page: 1, by: 200, search: bundle.name } })
                if (res.status < 200 || res.status >= 300) {
                    throw new Error(`GET /files -> HTTP ${res.status}: ${res.text.slice(0, 300)}`)
                }
                const notYet = bundle.fileNames.filter((f) => !res.text.includes(f.replace(/\.c4gh$/, '')))
                opts.log?.(`${total - notYet.length}/${total} files listed after ${Math.round((Date.now() - started) / 1000)}s`)
                return notYet.length === 0
                    ? { done: true as const, value: true }
                    : { done: false as const, note: `${notYet.length} of ${total} files not listed yet, e.g. ${notYet[0]}` }
            },
            { timeoutMs: opts.timeoutMs, intervalMs: opts.intervalMs }
        )
    } catch (err) {
        // What can this account see at all? An empty answer points to the wrong user (the files of a folder belong to the
        // portal user with that e-mail address), not to a slow cron job.
        const any = await api.raw('SUBMITTER', 'GET', '/files', { query: { page: 1, by: 3 } })
        throw new Error(`${(err as Error).message}\nWithout the search filter, this account sees (HTTP ${any.status}): ${any.text.slice(0, 700)}`)
    }
}

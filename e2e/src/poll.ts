export type PollResult<T> = { done: true; value: T } | { done: false; note: string }

export async function poll<T>(
    what: string,
    attempt: () => Promise<PollResult<T>>,
    opts: { timeoutMs: number; intervalMs: number }
): Promise<T> {
    const started = Date.now()
    let last = 'no attempt made'
    for (;;) {
        const result = await attempt()
        if (result.done) {
            return result.value
        }
        last = result.note
        const elapsed = Date.now() - started
        if (elapsed + opts.intervalMs > opts.timeoutMs) {
            throw new Error(`Timed out after ${Math.round(elapsed / 1000)}s waiting for: ${what}. Last observation: ${last}`)
        }
        await new Promise((resolve) => setTimeout(resolve, opts.intervalMs))
    }
}

import { spawn } from 'node:child_process'

export interface RunResult {
    code: number
    stdout: string
    stderr: string
}

export function run(
    command: string,
    args: string[],
    opts: { cwd?: string; input?: string; timeoutMs?: number } = {}
): Promise<RunResult> {
    return new Promise((resolve, reject) => {
        const child = spawn(command, args, { cwd: opts.cwd, stdio: ['pipe', 'pipe', 'pipe'] })
        let stdout = ''
        let stderr = ''
        const timer = opts.timeoutMs
            ? setTimeout(() => {
                  child.kill('SIGKILL')
                  reject(new Error(`${command} ${args.join(' ')} timed out after ${opts.timeoutMs} ms`))
              }, opts.timeoutMs)
            : undefined
        child.stdout.on('data', (d) => (stdout += d))
        child.stderr.on('data', (d) => (stderr += d))
        child.on('error', (err) => {
            if (timer) clearTimeout(timer)
            reject(new Error(`Cannot run ${command}: ${err.message}`))
        })
        child.on('close', (code) => {
            if (timer) clearTimeout(timer)
            resolve({ code: code ?? -1, stdout, stderr })
        })
        child.stdin.end(opts.input ?? '')
    })
}

export async function mustRun(command: string, args: string[], opts: Parameters<typeof run>[2] = {}): Promise<RunResult> {
    const result = await run(command, args, opts)
    if (result.code !== 0) {
        throw new Error(
            `${command} ${args.join(' ')} exited with ${result.code}\n${(result.stdout + result.stderr).slice(-2000)}`
        )
    }
    return result
}

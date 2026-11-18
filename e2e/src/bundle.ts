import crypto from 'node:crypto'
import fs from 'node:fs'
import path from 'node:path'
import { cfg, EXTRA_ATTRIBUTE_TAG } from './config'
import { mustRun, run } from './shell'

export interface Bundle {
    name: string
    dir: string
    zip: string
    studyTitle: string
    seed: string
    counts: { samples: number; experiments: number; runs: number; analyses: number; datasets: number; files: number }
    fileNames: string[]
    extraSampleAlias: string
    extraAttributeTag: string
}

const rows = (file: string): string[][] =>
    fs
        .readFileSync(file, 'utf8')
        .split('\n')
        .filter(Boolean)
        .map((l) => l.split('\t'))

const dataRows = (file: string): number => rows(file).length - 1

function stamp(): string {
    const d = new Date()
    const p = (n: number) => String(n).padStart(2, '0')
    return `${String(d.getFullYear()).slice(2)}${p(d.getMonth() + 1)}${p(d.getDate())}-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`
}

// A command line such as "php /path/to/fega.phar" is allowed for the CLI.
export const splitCommand = (command: string): [string, string[]] => {
    const [head, ...args] = command.trim().split(/\s+/)
    return [head, args]
}

// Phase 1.1: a unique bundle with the extra sample (no runs) and the extra study attribute.
export async function generateBundle(): Promise<Bundle> {
    const c = cfg()
    const name = `DEMO-E2E-${stamp()}`
    const seed = c.seed ?? String(Math.floor(Math.random() * 2_000_000_000) + 1)
    fs.mkdirSync(c.workdir, { recursive: true })
    await mustRun(c.php, [c.generator, '-n', name, '-p', String(c.patients), '-x', '-z', '-s', seed, '-o', c.workdir])

    const dir = path.join(c.workdir, name)
    const table = (kind: string) => path.join(dir, `${name}_${kind}.tsv`)
    const study = rows(table('study'))
    const titleColumn = study[0].indexOf('title')
    const fileNames = rows(path.join(dir, 'file_sizes.tsv')).map((r) => r[0])

    return {
        name,
        dir,
        zip: path.join(dir, `${name}.zip`),
        studyTitle: study[1][titleColumn],
        seed,
        counts: {
            samples: dataRows(table('samples')),
            experiments: dataRows(table('experiments')),
            runs: dataRows(table('runs')),
            analyses: dataRows(table('analyses')),
            datasets: dataRows(table('datasets')),
            files: fileNames.length
        },
        fileNames,
        extraSampleAlias: `${name}-E2E-TUMOR-01-DNA-01`,
        extraAttributeTag: EXTRA_ATTRIBUTE_TAG
    }
}

// Phase 1.2
export async function validateBundle(bundle: Bundle): Promise<string> {
    const [command, args] = splitCommand(cfg().fegaCli)
    const result = await mustRun(command, [...args, 'validate', bundle.zip], { timeoutMs: 120_000 })
    const output = result.stdout + result.stderr
    if (!/validated successfully/i.test(output)) {
        throw new Error(`fega-cli did not report a successful validation:\n${output.slice(-1500)}`)
    }
    return output
}

// Phase 1.3: the fake SDA of the demonstrator has no SFTP server: the inbox of a user is a folder named after the
// e-mail address, in the directory that the API container mounts. The cron job of the container registers every
// *.c4gh file it finds there (name, size and sha256: the content is not decrypted).
export function dropFiles(bundle: Bundle, email: string): { dir: string; written: number } {
    const dir = path.join(cfg().sdaInbox, email)
    fs.mkdirSync(dir, { recursive: true })
    for (const name of bundle.fileNames) {
        fs.writeFileSync(path.join(dir, name), crypto.randomBytes(512 + Math.floor(Math.random() * 1024)))
    }
    return { dir, written: bundle.fileNames.length }
}

// Names of the *.c4gh files currently in the inbox of a user.
export function listInbox(email: string): string[] {
    const dir = path.join(cfg().sdaInbox, email)
    return fs.existsSync(dir) ? fs.readdirSync(dir).filter((f) => f.endsWith('.c4gh')) : []
}

// Runs a command of the API container (the cron jobs) when asked to; never fails the test: the cron of the
// container runs every minute anyway.
export async function runInApiContainer(args: string[]): Promise<string> {
    const c = cfg()
    const result = await run('docker', ['compose', '-f', c.composeFile, 'exec', '-T', c.apiService, ...args], { timeoutMs: 120_000 }).catch((err: Error) => ({
        code: -1,
        stdout: '',
        stderr: err.message
    }))
    return `${result.code === 0 ? 'ok' : `exit ${result.code}`}: ${(result.stdout + result.stderr).trim().split('\n').slice(-3).join(' | ')}`
}

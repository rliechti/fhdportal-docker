import dns from 'node:dns/promises'
import fs from 'node:fs'
import { Api, asList } from './api'
import { accessToken, claims } from './auth'
import { splitCommand } from './bundle'
import { cfg, Role } from './config'
import { run } from './shell'

// The realm role each account must carry (looked for anywhere in the token, wherever Keycloak puts roles).
const ROLE_NAME: Partial<Record<Role, string>> = { SUBMITTER: 'submitter', HELPDESK: 'admin-fega', DAC: 'dac-cli' }

// Everything that can be checked before the test creates anything. Reports every problem at once instead of
// stopping at the first.
export async function preflight(api: Api, opts: { roles?: Role[] } = {}): Promise<string[]> {
    const problems: string[] = []
    const notes: string[] = []
    const check = async (what: string, fn: () => Promise<string | void>) => {
        try {
            const note = await fn()
            notes.push(`ok   ${what}${note ? `: ${note}` : ''}`)
        } catch (err) {
            problems.push(`${what}: ${(err as Error).message}`)
        }
    }

    let c: ReturnType<typeof cfg> | undefined
    await check('configuration', async () => {
        c = cfg()
        return `${c.apiUrl}, Keycloak ${c.keycloak.url} (realm ${c.keycloak.realm})`
    })
    if (!c) throw new Error(`Preflight failed, nothing was created:\n - ${problems.join('\n - ')}`)
    const conf = c

    await check('API answers (GET /schemas, public)', async () => {
        const host = new URL(conf.apiUrl).hostname
        await dns.lookup(host).catch((err) => {
            throw new Error(`cannot resolve ${host} (${(err as Error).message})`)
        })
        const res = await fetch(`${conf.apiUrl}/schemas`).catch((err: Error) => {
            throw new Error(`no answer from ${conf.apiUrl}/schemas: ${err.message}. Is the demonstrator running (docker compose up)?`)
        })
        if (!res.ok) throw new Error(`GET /schemas -> HTTP ${res.status}`)
        return `${Object.keys((await res.json()) as object).length} schemas`
    })

    for (const role of opts.roles ?? (['SUBMITTER', 'HELPDESK', 'OUTSIDER', 'DAC'] as Role[])) {
        await check(`token for ${role}`, async () => {
            const token = await accessToken(role)
            const payload = claims(token)
            if (!payload) return 'opaque token, claims not checked'
            const needed = ROLE_NAME[role]
            if (needed && !JSON.stringify(payload).includes(`"${needed}"`)) {
                throw new Error(`the token has no "${needed}" role (client ${payload.azp}, user ${payload.preferred_username ?? payload.sub})`)
            }
            const aud = Array.isArray(payload.aud) ? payload.aud : [payload.aud]
            if (!aud.includes(conf.keycloak.clientId)) {
                throw new Error(`"aud" is ${JSON.stringify(payload.aud)}: the API only accepts tokens whose audience includes "${conf.keycloak.clientId}"`)
            }
            return `${payload.preferred_username ?? payload.sub}, client ${payload.azp}, expires ${new Date(payload.exp * 1000).toISOString()}`
        })
    }
    await check('API accepts the submitter token', async () => `${asList(await api.get('SUBMITTER', '/submissions')).length} submissions visible`)

    await check('bundle generator', async () => {
        if (!fs.existsSync(conf.generator)) throw new Error(`generator not found: ${conf.generator}`)
        const php = await run(conf.php, ['-r', 'echo class_exists("ZipArchive") ? "ok" : "no-zip";'])
        if (php.stdout !== 'ok') throw new Error(`${conf.php} needs the zip extension (got "${php.stdout || php.stderr.trim()}")`)
    })
    await check('fega-cli', async () => {
        const [command, args] = splitCommand(conf.fegaCli)
        await run(command, [...args, '--help']) // only a missing executable fails here
    })
    await check('fake SDA inbox directory', async () => {
        fs.mkdirSync(conf.sdaInbox, { recursive: true })
        fs.accessSync(conf.sdaInbox, fs.constants.W_OK)
        return conf.sdaInbox
    })
    if (conf.triggerCron) {
        // not a problem when it fails: the cron job of the container runs every minute anyway
        try {
            const probe = await run('docker', ['compose', '-f', conf.composeFile, 'exec', '-T', conf.apiService, 'true'], { timeoutMs: 30_000 })
            notes.push(probe.code === 0 ? 'ok   docker compose reaches the API container (cron jobs are run on demand)' : `WARN docker compose cannot reach the API container: the test waits for the cron job of the container instead (${probe.stderr.trim().slice(0, 150)})`)
        } catch (err) {
            notes.push(`WARN no docker: the test waits for the cron job of the container instead (${(err as Error).message})`)
        }
    }

    if (problems.length) {
        throw new Error(`Preflight failed, nothing was created:\n - ${problems.join('\n - ')}\n\nChecked fine:\n${notes.join('\n')}`)
    }
    return notes
}

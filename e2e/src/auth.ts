import { cfg, checkedUrl, required, Role } from './config'

interface Cached {
    token: string
    exp: number
}

const cache: Partial<Record<Role, Cached>> = {}

// Passwords of the accounts created for this run (see keycloak-admin.ts): never written to disk.
const passwords: Partial<Record<Role, string>> = {}
export const setPassword = (role: Role, password: string) => {
    passwords[role] = password
    delete cache[role] // a token made before a password change or a new key stays valid, but claims may have changed
}
export const forgetTokens = () => {
    for (const role of Object.keys(cache) as Role[]) delete cache[role]
}

export function claims(token: string): any | undefined {
    const parts = token.split('.')
    return parts.length === 3 ? JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8')) : undefined
}

function expiry(token: string): number {
    const payload = claims(token)
    return payload ? (payload.exp ?? 0) * 1000 : Number.MAX_SAFE_INTEGER // opaque token: no way to know
}

export async function tokenRequest(url: string, form: Record<string, string>): Promise<{ access_token: string }> {
    checkedUrl('token url', url)
    let res: Response
    try {
        res = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/x-www-form-urlencoded' }, body: new URLSearchParams(form) })
    } catch (err) {
        const cause = (err as { cause?: { message?: string } }).cause?.message
        throw new Error(
            `Keycloak token request to ${url} failed: ${(err as Error).message}${cause ? ` (${cause})` : ''}.` +
                ` The demonstrator uses a self-signed certificate: set E2E_INSECURE_TLS=1.`
        )
    }
    const text = await res.text()
    if (!res.ok) {
        throw new Error(`Keycloak token request failed (${res.status}): ${text.slice(0, 300)}`)
    }
    return JSON.parse(text)
}

// Access token for a role. The submitter and the help desk log in as users (password grant); the DAC is a service
// account (client credentials), as the real DAC portal is when it sends its decisions to the API.
export async function accessToken(role: Role): Promise<string> {
    const cached = cache[role]
    if (cached && cached.exp - Date.now() > 30_000) return cached.token

    const fixed = process.env[`E2E_${role}_TOKEN`]
    if (fixed) {
        if (expiry(fixed) - Date.now() < 10_000) throw new Error(`E2E_${role}_TOKEN has expired: use a username and password for long runs`)
        cache[role] = { token: fixed, exp: expiry(fixed) }
        return fixed
    }

    const k = cfg().keycloak
    let answer: { access_token: string }
    if (role === 'DAC') {
        const form: Record<string, string> = {
            grant_type: 'client_credentials',
            client_id: k.dacClientId,
            client_secret: k.dacClientSecret ?? required('E2E_DAC_CLIENT_SECRET')
        }
        if (k.dacScope) form.scope = k.dacScope
        answer = await tokenRequest(k.tokenUrl, form)
    } else {
        const account = cfg().accounts[role]
        const form: Record<string, string> = {
            grant_type: 'password',
            client_id: k.clientId,
            username: account.username,
            password: passwords[role] ?? required(`E2E_${role}_PASSWORD`),
            scope: 'openid profile roles'
        }
        if (k.clientSecret) form.client_secret = k.clientSecret
        answer = await tokenRequest(k.tokenUrl, form)
    }
    cache[role] = { token: answer.access_token, exp: expiry(answer.access_token) }
    return answer.access_token
}

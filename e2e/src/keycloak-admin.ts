import crypto from 'node:crypto'
import { setPassword, tokenRequest } from './auth'
import { cfg, required } from './config'

// Creates (or finds) the accounts the scenario logs in with, in the Keycloak realm of the demonstrator, using the
// admin account of Keycloak. The realm ships with no human user. Every run sets a fresh random password: it is
// kept in memory only.

type Account = 'SUBMITTER' | 'HELPDESK' | 'OUTSIDER'

export interface AccountInfo {
    id: string
    username: string
    email: string
    created: boolean
}

let adminTokenCache: { token: string; exp: number } | undefined

async function adminToken(): Promise<string> {
    if (adminTokenCache && adminTokenCache.exp - Date.now() > 30_000) return adminTokenCache.token
    const k = cfg().keycloak
    const answer = await tokenRequest(k.adminTokenUrl, {
        grant_type: 'password',
        client_id: 'admin-cli',
        username: k.adminUser,
        password: k.adminPassword ?? required('E2E_KEYCLOAK_ADMIN_PASSWORD')
    })
    adminTokenCache = { token: answer.access_token, exp: Date.now() + 4 * 60_000 }
    return answer.access_token
}

async function admin(method: string, path: string, body?: unknown): Promise<Response> {
    const res = await fetch(`${cfg().keycloak.adminApi}${path}`, {
        method,
        headers: { authorization: `Bearer ${await adminToken()}`, ...(body === undefined ? {} : { 'content-type': 'application/json' }) },
        body: body === undefined ? undefined : JSON.stringify(body)
    })
    return res
}

async function must(res: Response, what: string): Promise<Response> {
    if (!res.ok) throw new Error(`Keycloak admin: ${what} failed (${res.status}): ${(await res.text()).slice(0, 300)}`)
    return res
}

async function findUser(username: string): Promise<{ id: string } | undefined> {
    const res = await must(await admin('GET', `/users?username=${encodeURIComponent(username)}&exact=true`), `look up ${username}`)
    const users = (await res.json()) as Array<{ id: string }>
    return users[0]
}

async function ensureUser(role: Account): Promise<AccountInfo> {
    const account = cfg().accounts[role]
    let user = await findUser(account.username)
    let created = false
    if (!user) {
        await must(
            await admin('POST', '/users', {
                username: account.username,
                email: account.email,
                emailVerified: true,
                enabled: true,
                firstName: 'E2E',
                lastName: role.charAt(0) + role.slice(1).toLowerCase()
            }),
            `create ${account.username}`
        )
        user = await findUser(account.username)
        created = true
    }
    if (!user) throw new Error(`Keycloak admin: ${account.username} not found after creation`)

    const password = crypto.randomBytes(18).toString('base64url')
    await must(await admin('PUT', `/users/${user.id}/reset-password`, { type: 'password', value: password, temporary: false }), `set the password of ${account.username}`)
    setPassword(role, password)

    if (account.role) {
        const realmRole = (await (await must(await admin('GET', `/roles/${account.role}`), `read role ${account.role}`)).json()) as { id: string; name: string }
        await must(await admin('POST', `/users/${user.id}/role-mappings/realm`, [realmRole]), `grant ${account.role} to ${account.username}`)
    }
    return { id: user.id, username: account.username, email: account.email, created }
}

export async function ensureAccounts(): Promise<Record<Account, AccountInfo>> {
    return { SUBMITTER: await ensureUser('SUBMITTER'), HELPDESK: await ensureUser('HELPDESK'), OUTSIDER: await ensureUser('OUTSIDER') }
}

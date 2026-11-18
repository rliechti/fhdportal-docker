import dotenv from 'dotenv'
import fs from 'node:fs'
import path from 'node:path'

export type Role = 'SUBMITTER' | 'HELPDESK' | 'OUTSIDER' | 'DAC'

// The demonstrator serves a self-signed certificate for Keycloak (port 8443): the test accepts it when asked to.
if (process.env.E2E_INSECURE_TLS === '1') process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'

const get = (name: string): string | undefined => {
    const v = process.env[name]
    return v === undefined || v === '' ? undefined : v
}

export function required(name: string): string {
    const v = get(name)
    if (v === undefined) {
        throw new Error(`Missing environment variable ${name} (see .env.example)`)
    }
    return v
}

// Fails early, with the offending value, on settings such as "https://https://host/...".
export function checkedUrl(name: string, value: string): string {
    let url: URL
    try {
        url = new URL(value)
    } catch {
        throw new Error(`${name} is not a valid URL: "${value}"`)
    }
    const schemeAsHost = /^https?$/.test(url.hostname)
    if (!/^https?:$/.test(url.protocol) || !url.hostname || schemeAsHost) {
        const hint = schemeAsHost ? ` (its host is "${url.hostname}": is the scheme written twice, as in https://https://...?)` : ''
        throw new Error(`${name} is not a usable http(s) URL: "${value}"${hint}`)
    }
    return value
}

const list = (name: string, fallback: string): string[] =>
    (get(name) ?? fallback)
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean)

const minutes = (name: string, fallback: number): number => Number(get(name) ?? fallback) * 60_000

export const e2eDir = path.resolve(__dirname, '..')

// The configuration of the demonstrator itself (../.env, the file docker compose reads) gives the defaults, so that
// the test needs no setting of its own on a stock demonstrator. Parsed only: nothing is put into process.env.
export function composeEnv(): Record<string, string> {
    try {
        return dotenv.parse(fs.readFileSync(path.join(e2eDir, '..', '.env')))
    } catch {
        return {}
    }
}

// Read lazily, so a missing variable only fails the step that needs it.
export function cfg() {
    const compose = composeEnv()
    const pick = (name: string, composeName: string, fallback?: string): string | undefined => get(name) ?? compose[composeName] ?? fallback
    const keycloakUrl = (pick('E2E_KEYCLOAK_URL', 'VITE_KEYCLOAK_URL', 'https://0.0.0.0:8443') as string).replace(/\/+$/, '')
    const realm = pick('E2E_KEYCLOAK_REALM', 'KEYCLOAK_REALM', 'fhdportal') as string
    const accountName = (role: 'SUBMITTER' | 'HELPDESK' | 'OUTSIDER', fallback: string) => get(`E2E_${role}_USERNAME`) ?? fallback
    return {
        apiUrl: checkedUrl('E2E_API_URL', get('E2E_API_URL') ?? 'http://localhost:5173/api').replace(/\/+$/, ''),
        keycloak: {
            url: checkedUrl('E2E_KEYCLOAK_URL', keycloakUrl),
            realm,
            tokenUrl: `${keycloakUrl}/realms/${realm}/protocol/openid-connect/token`,
            adminTokenUrl: `${keycloakUrl}/realms/master/protocol/openid-connect/token`,
            adminApi: `${keycloakUrl}/admin/realms/${realm}`,
            // user logins: a client with "Direct access grants" that the API accepts (azp in KEYCLOAK_ALLOWED_AZP)
            clientId: pick('E2E_KEYCLOAK_CLIENT_ID', 'KEYCLOAK_CLIENT_ID', 'fhdportal-cli') as string,
            clientSecret: pick('E2E_KEYCLOAK_CLIENT_SECRET', 'KEYCLOAK_SECRET'),
            // the DAC integration client: its token is what the real DAC portal sends back with its decisions
            dacClientId: pick('E2E_DAC_CLIENT_ID', 'KEYCLOAK_DAC_CLIENT_ID', 'dac-cli') as string,
            dacClientSecret: pick('E2E_DAC_CLIENT_SECRET', 'KEYCLOAK_DAC_SECRET'),
            // the API requires its own client in the audience of the token
            dacScope: get('E2E_DAC_SCOPE'),
            adminUser: pick('E2E_KEYCLOAK_ADMIN_USER', 'KC_BOOTSTRAP_ADMIN_USERNAME', 'admin') as string,
            adminPassword: pick('E2E_KEYCLOAK_ADMIN_PASSWORD', 'KC_BOOTSTRAP_ADMIN_PASSWORD')
        },
        // false: the accounts below are used as they are (E2E_<ROLE>_USERNAME + E2E_<ROLE>_PASSWORD, or E2E_<ROLE>_TOKEN)
        manageAccounts: get('E2E_MANAGE_ACCOUNTS') !== '0',
        accounts: {
            SUBMITTER: { username: accountName('SUBMITTER', 'e2e-submitter'), email: get('E2E_SUBMITTER_EMAIL') ?? 'e2e-submitter@example.org', role: 'submitter' as string | null },
            HELPDESK: { username: accountName('HELPDESK', 'e2e-helpdesk'), email: get('E2E_HELPDESK_EMAIL') ?? 'e2e-helpdesk@example.org', role: 'admin-fega' },
            // a logged-in user without any role of the portal: must not see anybody's submission
            OUTSIDER: { username: accountName('OUTSIDER', 'e2e-outsider'), email: get('E2E_OUTSIDER_EMAIL') ?? 'e2e-outsider@example.org', role: null as string | null }
        },
        php: get('E2E_PHP') ?? 'php',
        generator: path.resolve(get('E2E_GENERATOR') ?? path.join(e2eDir, 'create_test_bundle.php')),
        fegaCli: get('E2E_FEGA_CLI') ?? 'fega-cli',
        workdir: path.resolve(get('E2E_WORKDIR') ?? path.join(e2eDir, '.work')),
        patients: Number(get('E2E_PATIENTS') ?? 2),
        seed: get('E2E_SEED'),
        // The fake SDA: the files of a user are the *.c4gh files in a folder named after the e-mail address.
        sdaInbox: path.resolve(get('E2E_SDA_INBOX') ?? path.join(e2eDir, '..', 'sda-inbox')),
        // Run the cron jobs of the API container right away instead of waiting for the next minute
        triggerCron: get('E2E_TRIGGER_CRON') !== '0',
        composeFile: path.resolve(get('E2E_COMPOSE_FILE') ?? path.join(e2eDir, '..', 'compose.yml')),
        apiService: get('E2E_API_SERVICE') ?? 'api',
        policyTitle: get('E2E_POLICY_TITLE') ?? 'Standard Data Access Policy',
        requestAccepted: list('E2E_REQUEST_ACCEPTED', 'APR,approved').map((s) => s.toLowerCase()),
        requestFormOverrides: get('E2E_REQUEST_FORM_JSON'),
        filesTimeoutMs: minutes('E2E_FILES_TIMEOUT_MIN', 4),
        publishTimeoutMs: minutes('E2E_PUBLISH_TIMEOUT_MIN', 4),
        catalogueTimeoutMs: minutes('E2E_CATALOGUE_TIMEOUT_MIN', 2),
        // Beacon keeps its model of the published datasets for 5 minutes
        beaconTimeoutMs: minutes('E2E_BEACON_TIMEOUT_MIN', 6),
        pollIntervalMs: Number(get('E2E_POLL_INTERVAL_MS') ?? 5_000)
    }
}

export const EXTRA_ATTRIBUTE_TAG = 'e2e_extra_attribute'

import { APIRequestContext, request } from '@playwright/test'
import { accessToken } from './auth'
import { cfg, Role } from './config'

export class ApiError extends Error {}

export interface ApiResponse {
    status: number
    buffer: Buffer
    text: string
    body: any
}

type Method = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE'

interface CallOptions {
    json?: unknown
    multipart?: Record<string, string | { name: string; mimeType: string; buffer: Buffer }>
    query?: Record<string, string | number>
    timeoutMs?: number
}

export class Api {
    private constructor(private ctx: APIRequestContext) {}

    static async create(): Promise<Api> {
        return new Api(await request.newContext({ ignoreHTTPSErrors: process.env.E2E_INSECURE_TLS === '1' }))
    }

    dispose(): Promise<void> {
        return this.ctx.dispose()
    }

    // Never throws on an HTTP error status: use ok() / the helpers below for that.
    async raw(role: Role, method: Method, path: string, opts: CallOptions = {}): Promise<ApiResponse> {
        const token = await accessToken(role)
        const res = await this.ctx.fetch(`${cfg().apiUrl}${path}`, {
            method,
            headers: { Authorization: `Bearer ${token}`, 'x-access-token': `Bearer ${token}` },
            data: opts.json,
            multipart: opts.multipart,
            params: opts.query,
            timeout: opts.timeoutMs ?? 60_000
        })
        const buffer = await res.body()
        const text = buffer.toString('utf8')
        let body: any = undefined
        try {
            body = text ? JSON.parse(text) : undefined
        } catch {
            body = undefined
        }
        return { status: res.status(), buffer, text, body }
    }

    async call(role: Role, method: Method, path: string, opts: CallOptions = {}): Promise<any> {
        const res = await this.raw(role, method, path, opts)
        if (res.status < 200 || res.status >= 300) {
            throw new ApiError(`${method} ${path} as ${role} -> HTTP ${res.status}: ${res.text.slice(0, 500)}`)
        }
        return res.body
    }

    get = (role: Role, path: string, opts?: CallOptions) => this.call(role, 'GET', path, opts)
    post = (role: Role, path: string, json?: unknown, opts?: CallOptions) => this.call(role, 'POST', path, { ...opts, json })
    put = (role: Role, path: string, json?: unknown) => this.call(role, 'PUT', path, { json })
    patch = (role: Role, path: string, json?: unknown) => this.call(role, 'PATCH', path, { json })
    del = (role: Role, path: string) => this.call(role, 'DELETE', path)
}

// List endpoints answer with an array, or with an object wrapping/keying the rows.
export function asList(body: any): any[] {
    if (Array.isArray(body)) return body
    if (body && typeof body === 'object') {
        for (const key of ['data', 'items', 'rows', 'results']) {
            if (Array.isArray(body[key])) return body[key]
        }
        return Object.values(body).filter((v) => v && typeof v === 'object')
    }
    return []
}

// Streamed responses (bundle upload) are newline-delimited JSON.
export function parseNdjson(text: string): any[] {
    return text
        .split('\n')
        .map((l) => l.trim())
        .filter(Boolean)
        .map((l) => JSON.parse(l))
}

// First object anywhere in the tree for which `match` is true.
export function findDeep(node: any, match: (o: any) => boolean): any | undefined {
    if (node && typeof node === 'object') {
        if (!Array.isArray(node) && match(node)) return node
        for (const child of Object.values(node)) {
            const found = findDeep(child, match)
            if (found) return found
        }
    }
    return undefined
}

export function collectTitles(node: any, into: string[] = []): string[] {
    if (node && typeof node === 'object') {
        if (typeof node.title === 'string') into.push(node.title)
        for (const child of Object.values(node)) collectTitles(child, into)
    }
    return into
}

export const publicId = (resource: any): string => resource.public_id ?? resource.properties?.public_id

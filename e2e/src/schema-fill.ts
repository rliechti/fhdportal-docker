// Builds values for the data request form (a JSON Schema from the DAC portal) so a test
// does not need to know the questions: every required field gets a plausible value.
// Anything the schema cannot express can be forced with E2E_REQUEST_FORM_JSON.

function valueFor(name: string, schema: any, existing: any): any {
    if (existing !== undefined && existing !== null && existing !== '') return existing
    if (schema.default !== undefined) return schema.default
    if (schema.const !== undefined) return schema.const
    if (Array.isArray(schema.enum) && schema.enum.length) return schema.enum[0]
    if (Array.isArray(schema.oneOf) && schema.oneOf.length) return schema.oneOf[0].const ?? valueFor(name, schema.oneOf[0], undefined)

    const type = Array.isArray(schema.type) ? schema.type.find((t: string) => t !== 'null') : schema.type
    switch (type) {
        case 'object':
            return fillForm(schema, existing ?? {})
        case 'array':
            return schema.minItems > 0 && schema.items ? [valueFor(name, schema.items, undefined)] : (existing ?? [])
        case 'boolean':
            return true
        case 'integer':
        case 'number':
            return schema.minimum ?? 1
        case 'string':
        default:
            if (schema.format === 'email') return 'e2e@example.org'
            if (schema.format === 'date') return new Date().toISOString().slice(0, 10)
            return `E2E test ${name}`
    }
}

export function fillForm(schema: any, initial: any = {}, overrides: any = {}): any {
    const result: any = { ...initial }
    const required: string[] = schema.required ?? []
    for (const [name, sub] of Object.entries<any>(schema.properties ?? {})) {
        if (required.includes(name) || result[name] !== undefined) {
            result[name] = valueFor(name, sub, result[name])
        }
    }
    return deepMerge(result, overrides)
}

export function deepMerge(base: any, extra: any): any {
    if (!extra || typeof extra !== 'object' || Array.isArray(extra)) return extra ?? base
    const out: any = { ...(base ?? {}) }
    for (const [k, v] of Object.entries(extra)) {
        out[k] = v && typeof v === 'object' && !Array.isArray(v) ? deepMerge(out[k], v) : v
    }
    return out
}

// Purposes are checkboxes the schema does not mark as required, yet the DAC portal refuses the signed
// agreement of a request without any. Ticks the first checkbox found under a "purpose" field and returns
// its path (undefined when the form has none: then force the values with E2E_REQUEST_FORM_JSON).
export function selectPurpose(schema: any, values: any): string | undefined {
    const booleanLeaves = (node: any, path: string[]): string[][] => {
        const type = Array.isArray(node?.type) ? node.type.find((t: string) => t !== 'null') : node?.type
        if (type === 'boolean') return [path]
        return Object.entries<any>(node?.properties ?? {}).flatMap(([name, sub]) => booleanLeaves(sub, [...path, name]))
    }
    const candidates: string[][] = []
    const walk = (node: any, path: string[]) => {
        for (const [name, sub] of Object.entries<any>(node?.properties ?? {})) {
            const here = [...path, name]
            if (/purpose/i.test(name) || /purpose/i.test(sub?.title ?? '')) candidates.push(...booleanLeaves(sub, here))
            else walk(sub, here)
        }
    }
    walk(schema, [])
    if (!candidates.length) return undefined

    const target = candidates[0]
    let cursor = values
    for (const key of target.slice(0, -1)) {
        cursor[key] = cursor[key] && typeof cursor[key] === 'object' ? cursor[key] : {}
        cursor = cursor[key]
    }
    cursor[target[target.length - 1]] = true
    return target.join('.')
}

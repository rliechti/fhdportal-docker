#!/usr/bin/env node
// npm run e2e -- [--commit <version>] [--tester "<name>"] [playwright options]
// Runs the suite; the test report is written by the suite itself (src/markdown-report.ts).
const { spawnSync } = require('node:child_process')

const env = { ...process.env }
const rest = []
const options = { '--commit': 'E2E_COMMIT', '--tester': 'E2E_TESTER' }
const args = process.argv.slice(2)
for (let i = 0; i < args.length; i++) {
    if (options[args[i]]) {
        if (!args[i + 1]) {
            console.error(`${args[i]} needs a value`)
            process.exit(2)
        }
        env[options[args[i]]] = args[++i]
    } else {
        rest.push(args[i])
    }
}
const run = spawnSync('npx', ['playwright', 'test', ...rest], { stdio: 'inherit', env })
process.exit(run.status ?? 1)

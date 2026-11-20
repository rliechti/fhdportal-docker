import 'dotenv/config'
import { defineConfig } from '@playwright/test'

const results = process.env.E2E_RESULTS_DIR ?? 'results'

export default defineConfig({
    testDir: './tests',
    // The scenario is one ordered story that shares state, so: one worker, no retries.
    // A failed step makes the remaining steps of the (serial) scenario skip.
    workers: 1,
    fullyParallel: false,
    retries: 0,
    timeout: 120_000,
    // A demonstrator installed with HTTPS may serve a self-signed certificate
    use: { ignoreHTTPSErrors: process.env.E2E_INSECURE_TLS === '1' },
    reporter: [
        ['list'],
        ['html', { open: 'never', outputFolder: `${results}/html` }],
        ['junit', { outputFile: `${results}/junit.xml` }],
        ['./src/markdown-report.ts', { resultsDir: results }]
    ],
    outputDir: `${results}/artifacts`
})

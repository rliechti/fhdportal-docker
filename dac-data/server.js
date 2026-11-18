'use strict';
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PORT = process.env.PORT || 3000;
const DIR = __dirname;

const readJson = (name) => JSON.parse(fs.readFileSync(path.join(DIR, name), 'utf8'));

function sendJson(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body));
}

function drain(req) {
  return new Promise((resolve) => {
    req.on('data', () => {});
    req.on('end', resolve);
  });
}

const routes = [
  { method: 'GET', pattern: /^\/dacs\/[^/]+$/, handler: (req, res) => sendJson(res, 200, readJson('dac.json')) },
  { method: 'GET', pattern: /^\/submissions$/, handler: (req, res) => sendJson(res, 200, readJson('submissions.json')) },
  { method: 'POST', pattern: /^\/submissions$/, handler: async (req, res) => {
    await drain(req);
    sendJson(res, 200, readJson('submission-created.json'));
  } },
  { method: 'POST', pattern: /^\/datarequests$/, handler: async (req, res) => {
    await drain(req);
    const body = readJson('datarequest-created.json');
    body.id = crypto.randomUUID();
    sendJson(res, 200, body);
  } },
  { method: 'GET', pattern: /^\/datarequests\/[^/]+\/requester-form$/, handler: (req, res) => sendJson(res, 200, readJson('requester-form.json')) },
  { method: 'POST', pattern: /^\/datarequests\/[^/]+\/attachments$/, handler: async (req, res) => {
    await drain(req);
    const body = readJson('attachment-created.json');
    body.id = crypto.randomUUID();
    sendJson(res, 200, body);
  } },
  { method: 'PATCH', pattern: /^\/datarequests\/[^/]+$/, handler: async (req, res) => {
    await drain(req);
    sendJson(res, 200, readJson('datarequest-updated.json'));
  } },
  { method: 'GET', pattern: /^\/datarequests\/[^/]+\/daa$/, handler: (req, res) => {
    res.writeHead(200, {
      'Content-Type': 'application/pdf',
      'Content-Disposition': 'attachment; filename="daa.pdf"',
    });
    res.end(fs.readFileSync(path.join(DIR, 'daa.pdf')));
  } },
  { method: 'GET', pattern: /^\/policies$/, handler: (req, res) => sendJson(res, 200, readJson('policies.json')) },
  { method: 'GET', pattern: /^\/policies\/[^/]+\/[^/]+$/, handler: (req, res) => sendJson(res, 200, readJson('policy-form.json')) },
  { method: 'GET', pattern: /^\/policies\/[^/]+$/, handler: (req, res) => sendJson(res, 200, readJson('policy.json')) },
];

const server = http.createServer((req, res) => {
  const pathname = new URL(req.url, 'http://internal').pathname;
  const route = routes.find((r) => r.method === req.method && r.pattern.test(pathname));
  console.log(`${req.method} ${pathname} -> ${route ? 'matched' : '404'}`);

  if (!route) {
    drain(req).then(() => sendJson(res, 404, { error: 'No mock response configured', method: req.method, path: pathname }));
    return;
  }

  Promise.resolve(route.handler(req, res)).catch((err) => {
    console.error(err);
    if (!res.headersSent) sendJson(res, 500, { error: 'Mock server error' });
  });
});

server.listen(PORT, () => console.log(`Mock DAC Portal API listening on :${PORT}`));

import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { test } from 'node:test';
import { buildDemoPlan } from '../repair-engine.js';
import { handleRequest } from '../server.js';

class MockRequest extends EventEmitter {
  constructor({ method = 'GET', url = '/', headers = {}, body = null } = {}) {
    super();
    this.method = method;
    this.url = url;
    this.headers = headers;
    this.body = body;
  }

  setEncoding() {}
}

class MockResponse {
  constructor() {
    this.statusCode = 0;
    this.headers = {};
    this.body = '';
    this.done = new Promise((resolve) => {
      this.resolve = resolve;
    });
  }

  writeHead(statusCode, headers) {
    this.statusCode = statusCode;
    this.headers = headers;
  }

  end(body = '') {
    this.body += body;
    this.resolve();
  }
}

async function request(options) {
  const req = new MockRequest(options);
  const res = new MockResponse();
  const responsePromise = handleRequest(req, res, {
    analyze: async (input) => ({ ...buildDemoPlan(input), requestId: 'test-request' }),
  });
  if (options.body !== null && options.body !== undefined) {
    req.emit('data', options.body);
  }
  req.emit('end');
  await Promise.all([responsePromise, res.done]);
  return {
    status: res.statusCode,
    headers: res.headers,
    body: res.body ? JSON.parse(res.body) : null,
  };
}

test('health endpoint reports the deterministic mode and handles query strings', async () => {
  const response = await request({ method: 'GET', url: '/health?probe=1' });
  assert.equal(response.status, 200);
  assert.equal(response.body.ok, true);
  assert.match(response.body.mode, /^(demo-fallback|nebius-configured)$/);
});

test('analyze endpoint returns the complete repair contract', async () => {
  const response = await request({
    method: 'POST',
    url: '/api/repair/analyze',
    headers: { 'content-type': 'application/json; charset=utf-8' },
    body: JSON.stringify({ equipment: 'Pump', symptom: 'Stops under load' }),
  });
  assert.equal(response.status, 200);
  assert.equal(response.body.equipment, 'Pump');
  assert.ok(response.body.requestId);
  assert.equal(response.body.actionable, false);
  assert.deepEqual(response.body.steps, []);
});

test('analyze endpoint requires both issue fields', async () => {
  const response = await request({
    method: 'POST',
    url: '/api/repair/analyze',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ equipment: 'Pump' }),
  });
  assert.equal(response.status, 422);
  assert.deepEqual(response.body, { error: 'equipment and symptom are required' });
});

test('analyze endpoint rejects malformed and incorrectly typed bodies', async () => {
  const malformed = await request({
    method: 'POST',
    url: '/api/repair/analyze',
    headers: { 'content-type': 'application/json' },
    body: '{',
  });
  assert.equal(malformed.status, 400);

  const wrongType = await request({
    method: 'POST',
    url: '/api/repair/analyze',
    headers: { 'content-type': 'text/plain' },
    body: '{}',
  });
  assert.equal(wrongType.status, 415);
});

test('analyze endpoint rejects bodies larger than 64 KiB', async () => {
  const response = await request({
    method: 'POST',
    url: '/api/repair/analyze',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ equipment: 'Pump', symptom: 'x'.repeat(70 * 1024) }),
  });
  assert.equal(response.status, 413);
  assert.deepEqual(response.body, { error: 'Request body too large' });
});

test('unknown routes return JSON 404 responses', async () => {
  const response = await request({ method: 'GET', url: '/missing' });
  assert.equal(response.status, 404);
  assert.deepEqual(response.body, { error: 'Not found' });
});

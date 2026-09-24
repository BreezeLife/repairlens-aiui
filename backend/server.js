import http from 'node:http';
import { randomUUID } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { buildDemoPlan, buildPrompt, normalizeModelPlan } from './repair-engine.js';

const MAX_BODY_BYTES = 64 * 1024;

class HttpError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.statusCode = statusCode;
  }
}

function getTimeoutMs() {
  const configured = Number(process.env.NEBIUS_TIMEOUT_MS || 12000);
  return Number.isFinite(configured) && configured > 0 ? configured : 12000;
}

function isNebiusConfigured() {
  return Boolean(process.env.NEBIUS_API_URL && process.env.NEBIUS_API_KEY && process.env.NEBIUS_MODEL);
}

function sendJson(response, statusCode, body) {
  const payload = JSON.stringify(body);
  response.writeHead(statusCode, {
    'content-type': 'application/json; charset=utf-8',
    'content-length': Buffer.byteLength(payload),
    'access-control-allow-origin': '*',
    'access-control-allow-headers': 'content-type',
  });
  response.end(payload);
}

function readJson(request) {
  return new Promise((resolve, reject) => {
    let size = 0;
    let body = '';
    let failed = false;
    request.setEncoding('utf8');
    request.on('data', (chunk) => {
      if (failed) {
        return;
      }
      size += Buffer.byteLength(chunk);
      if (size > MAX_BODY_BYTES) {
        failed = true;
        reject(new HttpError(413, 'Request body too large'));
        return;
      }
      body += chunk;
    });
    request.on('end', () => {
      if (failed) {
        return;
      }
      if (!body.trim()) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(body));
      } catch {
        reject(new HttpError(400, 'Request body must be valid JSON'));
      }
    });
    request.on('error', reject);
  });
}

async function callNebius(input) {
  const apiUrl = process.env.NEBIUS_API_URL;
  const apiKey = process.env.NEBIUS_API_KEY;
  const model = process.env.NEBIUS_MODEL;
  if (!apiUrl || !apiKey || !model) {
    return null;
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), getTimeoutMs());
  try {
    const response = await fetch(apiUrl, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        authorization: `Bearer ${apiKey}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model,
        temperature: 0.1,
        response_format: { type: 'json_object' },
        messages: [
          {
            role: 'system',
            content: 'Return a conservative, source-grounded repair plan as JSON only.',
          },
          { role: 'user', content: buildPrompt(input) },
        ],
      }),
    });
    if (!response.ok) {
      throw new Error(`Nebius endpoint returned ${response.status}`);
    }
    const payload = await response.json();
    const content = payload?.choices?.[0]?.message?.content;
    return normalizeModelPlan(content, { ...input, model });
  } finally {
    clearTimeout(timer);
  }
}

async function analyzeRepair(input, callProvider = callNebius) {
  const requestId = randomUUID();
  try {
    const cloudPlan = await callProvider(input);
    if (cloudPlan) {
      return { ...cloudPlan, requestId };
    }
  } catch (error) {
    return {
      ...buildDemoPlan(input),
      provider: 'demo-fallback',
      requestId,
      warning: error instanceof Error ? error.message : 'Nebius request failed',
    };
  }
  return { ...buildDemoPlan(input), requestId };
}

function validateAnalyzeInput(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw new HttpError(400, 'Request body must be a JSON object');
  }
  const equipment = typeof input.equipment === 'string' ? input.equipment.trim() : '';
  const symptom = typeof input.symptom === 'string' ? input.symptom.trim() : '';
  const context = typeof input.context === 'string' ? input.context.trim() : '';
  if (!equipment || !symptom) {
    throw new HttpError(422, 'equipment and symptom are required');
  }
  return {
    equipment: equipment.slice(0, 120),
    symptom: symptom.slice(0, 500),
    context: context.slice(0, 500),
  };
}

async function handleRequest(request, response, { analyze = analyzeRepair } = {}) {
  const url = new URL(request.url || '/', 'http://repairlens.local');

    if (request.method === 'OPTIONS') {
      response.writeHead(204, {
        'access-control-allow-origin': '*',
        'access-control-allow-headers': 'content-type',
        'access-control-allow-methods': 'GET,POST,OPTIONS',
      });
      response.end();
      return;
    }

    if (request.method === 'GET' && url.pathname === '/health') {
      sendJson(response, 200, {
        ok: true,
        service: 'repairlens-backend',
        mode: isNebiusConfigured() ? 'nebius-configured' : 'demo-fallback',
      });
      return;
    }

    if (request.method === 'POST' && url.pathname === '/api/repair/analyze') {
      try {
        const contentType = request.headers['content-type'] || '';
        if (!contentType.toLowerCase().startsWith('application/json')) {
          throw new HttpError(415, 'content-type must be application/json');
        }
        const input = await readJson(request);
        const plan = await analyze(validateAnalyzeInput(input));
        sendJson(response, 200, plan);
      } catch (error) {
        sendJson(response, error instanceof HttpError ? error.statusCode : 500, {
          error: error instanceof Error ? error.message : 'Invalid request',
        });
      }
      return;
    }

    sendJson(response, 404, { error: 'Not found' });
}

function createServer({ analyze = analyzeRepair } = {}) {
  return http.createServer((request, response) => handleRequest(request, response, { analyze }));
}

const server = createServer();
const isMain = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;

if (isMain) {
  const configuredPort = Number(process.env.PORT || 8787);
  const port = Number.isInteger(configuredPort) && configuredPort > 0 ? configuredPort : 8787;
  const host = process.env.HOST || '127.0.0.1';
  server.listen(port, host, () => {
    console.log(`RepairLens backend listening on http://${host}:${port}`);
  });
}

export { analyzeRepair, callNebius, createServer, handleRequest, isNebiusConfigured, server };

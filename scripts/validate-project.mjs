import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const root = process.cwd();
const requiredFiles = [
  'LICENSE',
  'README.md',
  'aiui/AGENTS.md',
  'aiui/app.json',
  'aiui/app.js',
  'aiui/app.wxss',
  'aiui/aiui-audit-claims.json',
  'aiui/pages/home/index.ink',
  'backend/package.json',
  'backend/server.js',
  'backend/repair-engine.js',
  'docs/architecture.md',
  'docs/device-validation.md',
];
const errors = [];

function read(relativePath) {
  const absolutePath = path.join(root, relativePath);
  if (!fs.existsSync(absolutePath)) {
    errors.push(`missing required file: ${relativePath}`);
    return '';
  }
  return fs.readFileSync(absolutePath, 'utf8');
}

function readJson(relativePath) {
  const content = read(relativePath);
  if (!content) return null;
  try {
    return JSON.parse(content);
  } catch (error) {
    errors.push(`invalid JSON in ${relativePath}: ${error.message}`);
    return null;
  }
}

for (const relativePath of requiredFiles) read(relativePath);

const app = readJson('aiui/app.json');
const appEntry = read('aiui/app.js');
const page = read('aiui/pages/home/index.ink');
const audit = readJson('aiui/aiui-audit-claims.json');
const backendPackage = readJson('backend/package.json');

if (!app || !Array.isArray(app.pages) || app.pages.length !== 1 || app.pages[0] !== 'pages/home/index') {
  errors.push('aiui/app.json must declare only pages/home/index');
}
if (!appEntry.includes("targetVersion: '0.17.0'")) {
  errors.push('aiui/app.js must declare targetVersion 0.17.0');
}
for (const marker of ['<script setup>', '<page>', '<style>', 'onVoiceWakeup', 'onKeyDown', 'onKeyUp', 'fetchWithTimeout', 'REQUEST_TIMEOUT_MS', '/api/repair/analyze']) {
  if (!page.includes(marker)) errors.push(`AIUI page is missing ${marker}`);
}
if (page.includes('GlobalHook')) {
  errors.push('AIUI source must not claim unverified GlobalHook support');
}
if (!audit || audit.schemaVersion !== 1 || audit.scopeClosed !== true || !Array.isArray(audit.claims)) {
  errors.push('AIUI audit claims must be a closed schema-1 scope with an array of claims');
}
if (!backendPackage || backendPackage.scripts?.test !== 'node --test') {
  errors.push('backend/package.json must expose the node test runner');
}

if (errors.length) {
  console.error('RepairLens validation failed');
  for (const error of errors) console.error(`- ${error}`);
  process.exitCode = 1;
} else {
  console.log(`RepairLens validation passed (${requiredFiles.length} required files, AIUI 0.17 contract present)`);
}

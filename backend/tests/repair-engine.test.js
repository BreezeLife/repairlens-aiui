import test from 'node:test';
import assert from 'node:assert/strict';
import { buildDemoPlan, buildPrompt, normalizeModelPlan } from '../repair-engine.js';
import { analyzeRepair } from '../server.js';

test('demo plan is deterministic and contains a safety-first sequence', () => {
  const plan = buildDemoPlan({
    equipment: 'HVAC condenser',
    symptom: 'Fan starts, then stops after two minutes',
  });
  assert.equal(plan.provider, 'demo-fallback');
  assert.equal(plan.actionable, true);
  assert.equal(plan.steps[0].id, 'isolate');
  assert.match(plan.steps[0].detail, /disconnect|power/i);
  assert.ok(plan.evidence.length > 0);
});

test('offline mode blocks repair steps for cases without a fixture', () => {
  const plan = buildDemoPlan({ equipment: 'Pump controller', symptom: 'Controller resets under load' });
  assert.equal(plan.actionable, false);
  assert.equal(plan.risk, 'UNKNOWN');
  assert.deepEqual(plan.steps, []);
  assert.deepEqual(plan.evidence, []);
  assert.match(plan.nextAction, /equipment-specific service procedure/);
});

test('model response is normalized into the glasses contract', () => {
  const plan = normalizeModelPlan(
    JSON.stringify({
      equipment: 'Compressor',
      summary: 'Check the pressure switch first.',
      risk: 'high',
      nextAction: 'Confirm isolation.',
      steps: [{ title: 'Isolate', detail: 'Disconnect power.', confirmPrompt: 'Isolated?' }],
      evidence: [{ title: 'Manual', source: 'service-manual.pdf', excerpt: 'Section 2' }],
    }),
    { model: 'nvidia-test', equipment: 'Compressor' },
  );
  assert.equal(plan.provider, 'nebius');
  assert.equal(plan.model, 'nvidia-test');
  assert.equal(plan.risk, 'HIGH');
  assert.equal(plan.steps[0].id, 'step-1');
});

test('prompt requests conservative JSON and includes the issue context', () => {
  const prompt = buildPrompt({ equipment: 'Valve', symptom: 'Leaks', context: 'field test' });
  assert.match(prompt, /Return JSON only/);
  assert.match(prompt, /ISSUE_JSON/);
  assert.match(prompt, /"equipment":"Valve"/);
  assert.match(prompt, /"symptom":"Leaks"/);
  assert.match(prompt, /untrusted field data/);
});

test('model response must include a usable evidence source', () => {
  assert.throws(
    () => normalizeModelPlan({ steps: [{ title: 'Inspect' }], evidence: [] }),
    /no usable evidence/,
  );
});

test('model fields are bounded and unsupported risk values become unknown', () => {
  const plan = normalizeModelPlan({
    summary: 'x'.repeat(700),
    risk: 'safe',
    steps: [{ title: 'Inspect' }],
    evidence: [{ source: 'manual.pdf' }],
  });
  assert.equal(plan.summary.length, 500);
  assert.equal(plan.risk, 'UNKNOWN');
});

test('provider failures return a deterministic warning-bearing fallback', async () => {
  const plan = await analyzeRepair(
    { equipment: 'Pump', symptom: 'Stops under load' },
    async () => {
      throw new Error('provider unavailable');
    },
  );
  assert.equal(plan.provider, 'demo-fallback');
  assert.equal(plan.warning, 'provider unavailable');
  assert.equal(plan.actionable, false);
  assert.ok(plan.requestId);
});

test('an empty provider result falls back without exposing repair steps for an unknown case', async () => {
  const plan = await analyzeRepair(
    { equipment: 'Pump', symptom: 'Stops under load' },
    async () => null,
  );
  assert.equal(plan.provider, 'demo-fallback');
  assert.equal(plan.actionable, false);
  assert.deepEqual(plan.steps, []);
  assert.ok(plan.requestId);
});

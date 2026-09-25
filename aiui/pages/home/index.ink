<script type="application/json" def>
{
  "navigationBarTitleText": "RepairLens"
}
</script>

<script setup>
import wx from 'wx';

const REQUEST_TIMEOUT_MS = 14000;
const RISK_LEVELS = new Set(['LOW', 'MEDIUM', 'HIGH', 'CRITICAL', 'UNKNOWN', 'UNASSESSED']);
let requestSequence = 0;

function compactText(value, fallback, maxLength) {
  const normalized = typeof value === 'string' ? value.trim() : '';
  if (!normalized) {
    return fallback;
  }
  if (normalized.length <= maxLength) {
    return normalized;
  }
  return `${normalized.slice(0, Math.max(1, maxLength - 3)).trimEnd()}...`;
}

function compactSingleLine(value, fallback, maxLength) {
  const normalized = typeof value === 'string' ? value.replace(/\s+/g, ' ').trim() : '';
  return compactText(normalized, fallback, maxLength);
}

function compactRisk(value, fallback = 'UNKNOWN') {
  const normalized = typeof value === 'string' ? value.trim().toUpperCase() : '';
  return RISK_LEVELS.has(normalized) ? normalized : fallback;
}

function fetchWithTimeout(url, options, timeoutMs = REQUEST_TIMEOUT_MS) {
  let timer;
  const controller = typeof AbortController === 'function' ? new AbortController() : null;
  const requestOptions = controller ? { ...options, signal: controller.signal } : options;
  const request = Promise.resolve().then(() => fetch(url, requestOptions));
  const timeout = new Promise((resolve, reject) => {
    timer = setTimeout(() => {
      if (controller) {
        controller.abort();
      }
      reject(new Error('repair API timed out'));
    }, timeoutMs);
  });
  return Promise.race([request, timeout]).then(
    (value) => {
      clearTimeout(timer);
      return value;
    },
    (error) => {
      clearTimeout(timer);
      if (controller) {
        controller.abort();
      }
      throw error;
    },
  );
}

const DEMO_PLAN = {
  provider: 'demo-fallback',
  model: 'repairlens-demo',
  equipment: 'HVAC condenser',
  summary: 'The condenser fan starts and then stops. Start with airflow and power checks before opening the electrical panel.',
  risk: 'MEDIUM',
  nextAction: 'Confirm the unit is isolated before inspecting the filter and outdoor coil.',
  steps: [
    {
      id: 'isolate',
      title: 'Isolate power',
      detail: 'Switch off the local disconnect and confirm the fan has stopped before touching the unit.',
      confirmPrompt: 'Power isolated and fan stopped?',
    },
    {
      id: 'airflow',
      title: 'Check airflow',
      detail: 'Inspect the filter and outdoor coil for blockage. Do not remove panels while power is connected.',
      confirmPrompt: 'Filter and coil checked?',
    },
    {
      id: 'record',
      title: 'Record evidence',
      detail: 'Capture the observed symptom, ambient conditions, and any visible obstruction in the service record.',
      confirmPrompt: 'Evidence recorded?',
    },
  ],
  evidence: [
    {
      title: 'Demo procedure',
      source: 'RepairLens deterministic fixture',
      excerpt: 'Safety-first sequence for a condenser fan that stops after startup.',
    },
  ],
};

function initialState() {
  return {
    flowState: 'ready',
    status: 'READY',
    equipment: 'HVAC condenser',
    symptom: 'Fan starts, then stops after two minutes',
    summary: 'Review this HVAC demo case, then confirm one action at a time.',
    risk: 'UNASSESSED',
    nextAction: 'Ready to load the demo repair plan.',
    steps: [],
    currentStepIndex: 0,
    currentStepTitle: 'No active step',
    currentStepDetail: 'The next verified action will appear here.',
    currentStepPrompt: 'Awaiting a repair plan',
    evidence: [],
    evidenceTitle: '',
    evidenceSource: '',
    provider: 'offline',
    lastInput: 'None',
    error: '',
    requestToken: 0,
  };
}

function normalizePlan(plan) {
  if (!plan || typeof plan !== 'object' || Array.isArray(plan)) {
    throw new Error('Repair plan is invalid');
  }
  const source = plan;
  if (source.actionable === false) {
    return {
      provider: compactSingleLine(source.provider, 'unknown', 18),
      equipment: compactSingleLine(source.equipment, DEMO_PLAN.equipment, 40),
      summary: compactText(source.summary, 'No approved procedure is available for this case.', 100),
      risk: compactRisk(source.risk),
      nextAction: compactText(source.nextAction, 'Pause work and obtain the equipment-specific service procedure.', 80),
      steps: [],
      evidence: [],
      actionable: false,
    };
  }
  if (typeof source.equipment !== 'string'
    || source.equipment.trim().toLowerCase() !== DEMO_PLAN.equipment.toLowerCase()
    || !Array.isArray(source.steps) || !source.steps.length
    || !source.steps.every((step) => step && typeof step.title === 'string' && step.title.trim()
      && typeof step.detail === 'string' && step.detail.trim())
    || !Array.isArray(source.evidence) || !source.evidence.length
    || !source.evidence.some((item) => item && typeof item.source === 'string' && item.source.trim())) {
    throw new Error('Repair plan is incomplete');
  }
  const rawSteps = source.steps;
  const evidence = source.evidence
    .filter((item) => item && typeof item.source === 'string' && item.source.trim())
    .slice(0, 3)
    .map((item, index) => ({
      title: compactSingleLine(item.title, `Source ${index + 1}`, 24),
      source: compactSingleLine(item.source, 'Unspecified source', 36),
      excerpt: compactText(item.excerpt, '', 60),
    }));
  const steps = rawSteps.slice(0, 6).map((step, index) => ({
    id: compactSingleLine(step.id, `step-${index + 1}`, 32),
    title: compactSingleLine(step.title, `Step ${index + 1}`, 28),
    detail: compactText(step.detail, 'Follow the verified procedure.', 100),
    confirmPrompt: compactText(step.confirmPrompt, 'Confirm this action is complete?', 48),
  }));
  return {
    provider: compactSingleLine(source.provider, 'unknown', 18),
    equipment: compactSingleLine(source.equipment, DEMO_PLAN.equipment, 40),
    summary: compactText(source.summary, DEMO_PLAN.summary, 100),
    risk: compactRisk(source.risk),
    nextAction: compactText(source.nextAction, DEMO_PLAN.nextAction, 80),
    steps,
    evidence,
    warning: compactText(source.warning, '', 72),
    actionable: true,
  };
}

function getCurrentStep(plan, index) {
  const step = plan.steps[index] || plan.steps[plan.steps.length - 1] || DEMO_PLAN.steps[0];
  return {
    currentStepTitle: step.title || 'Next verified action',
    currentStepDetail: step.detail || 'Follow the procedure and confirm when complete.',
    currentStepPrompt: step.confirmPrompt || 'Confirm this action is complete.',
  };
}

export default {
  data: initialState(),

  onLoad() {
    this.setData({
      lastInput: 'Page loaded',
    });
  },

  onVoiceWakeup(event) {
    const keyword = event && event.keyword ? event.keyword : 'voice';
    this.setData({ lastInput: `Wakeup: ${keyword}` });
    if (this.data.flowState === 'ready' || this.data.flowState === 'error') {
      this.startRepair();
    }
  },

  onKeyDown(event) {
    if (event && event.code === 'Enter') {
      this.setData({ lastInput: 'Enter down' });
    }
  },

  onKeyUp(event) {
    if (event && event.code === 'Backspace') {
      this.setData({ lastInput: 'Back pressed; host may exit' });
      return;
    }

    if (event && event.code === 'Enter') {
      if (this.data.flowState === 'ready' || this.data.flowState === 'error') {
        this.startRepair();
      } else if (this.data.flowState === 'step') {
        this.confirmStep();
      } else if (this.data.flowState === 'complete') {
        this.resetFlow();
      }
    }
  },

  startRepair() {
    if (this.data.flowState !== 'ready' && this.data.flowState !== 'error') {
      return;
    }

    const requestToken = ++requestSequence;
    this.setData({
      flowState: 'loading',
      status: 'ANALYZING',
      summary: 'Building a grounded repair plan...',
      nextAction: 'Waiting for the repair procedure.',
      error: '',
      currentStepTitle: 'Analyzing issue',
      currentStepDetail: 'The Agent is checking the symptom against the repair workflow.',
      currentStepPrompt: 'Please wait',
      lastInput: 'Start repair',
      requestToken,
    });

    const app = getApp();
    const configuredBaseUrl = app && app.globalData && app.globalData.apiBaseUrl
      ? app.globalData.apiBaseUrl
      : 'http://127.0.0.1:8787';
    const baseUrl = configuredBaseUrl.replace(/\/+$/, '');

    fetchWithTimeout(`${baseUrl}/api/repair/analyze`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        equipment: this.data.equipment,
        symptom: this.data.symptom,
        context: 'ROKID Glasses hands-free repair workflow',
      }),
    })
      .then((response) => {
        if (!response.ok) {
          throw new Error(`Repair API returned ${response.status}`);
        }
        return response.json();
      })
      .then((plan) => {
        if (this.data.requestToken === requestToken) {
          this.applyPlan(normalizePlan(plan));
        }
      })
      .catch((error) => {
        if (this.data.requestToken !== requestToken) {
          return;
        }
        const fallback = normalizePlan(DEMO_PLAN);
        const message = error instanceof Error && /timed out/i.test(error.message)
          ? 'OFFLINE PLAN: request timed out'
          : error instanceof Error && /Repair plan/i.test(error.message)
            ? 'OFFLINE PLAN: invalid provider response'
            : 'OFFLINE PLAN: network unavailable';
        this.applyPlan(fallback, true, message);
      });
  },

  applyPlan(plan, usedFallback = false, fallbackMessage = '') {
    if (!plan.actionable) {
      this.setData({
        flowState: 'blocked',
        status: 'PROCEDURE NEEDED',
        summary: plan.summary,
        risk: plan.risk,
        nextAction: plan.nextAction,
        steps: [],
        evidence: [],
        provider: compactSingleLine(plan.provider, 'unknown', 18),
        lastInput: 'Case paused',
      });
      return;
    }
    const stepState = getCurrentStep(plan, 0);
    const isOffline = usedFallback || plan.provider === 'demo-fallback' || Boolean(plan.warning);
    this.setData({
      flowState: 'step',
      status: isOffline ? 'OFFLINE PLAN' : 'PLAN READY',
      summary: plan.summary,
      risk: plan.risk,
      nextAction: plan.nextAction,
      steps: plan.steps,
      currentStepIndex: 0,
      ...stepState,
      evidence: plan.evidence,
      evidenceTitle: plan.evidence[0] && plan.evidence[0].title ? plan.evidence[0].title : 'Source available',
      evidenceSource: plan.evidence[0] && plan.evidence[0].source ? plan.evidence[0].source : 'Unspecified source',
      provider: compactSingleLine(usedFallback ? 'demo-fallback' : plan.provider, 'unknown', 18),
      error: usedFallback
        ? fallbackMessage || 'OFFLINE PLAN: network unavailable'
        : (plan.warning ? `OFFLINE PLAN: ${compactText(plan.warning, 'provider unavailable', 72)}` : ''),
      lastInput: 'Repair plan ready',
    });
  },

  confirmStep() {
    if (this.data.flowState !== 'step') {
      return;
    }

    const nextIndex = this.data.currentStepIndex + 1;
    if (nextIndex >= this.data.steps.length) {
      this.setData({
        flowState: 'complete',
        status: 'RECORDED',
        nextAction: 'Session confirmation recorded; durable export is not enabled in v0.',
        currentStepTitle: 'Repair sequence complete',
        currentStepDetail: 'All planned actions were explicitly confirmed on the glasses.',
        currentStepPrompt: 'Start a new case when ready.',
        lastInput: 'Step confirmed',
      });
      return;
    }

    this.setData({
      currentStepIndex: nextIndex,
      ...getCurrentStep({ steps: this.data.steps }, nextIndex),
      lastInput: 'Step confirmed',
    });
  },

  resetFlow() {
    this.setData({
      ...initialState(),
      requestToken: ++requestSequence,
      lastInput: 'New case',
    });
  },
};
</script>

<page>
  <view class="screen">
    <view class="topbar">
      <text class="brand">REPAIRLENS</text>
      <text class="device">ROKID GLASSES</text>
    </view>

    <view class="status-line">
      <text class="status-dot">●</text>
      <text class="status">{{status}}</text>
      <text class="provider">{{provider}}</text>
    </view>

    <view class="case-panel" ink:if="{{flowState === 'ready' || flowState === 'loading' || flowState === 'error' || flowState === 'blocked'}}">
      <text class="label">DEMO CASE</text>
      <text class="case-title">{{equipment}}</text>
      <text class="symptom">{{symptom}}</text>
    </view>

    <view class="summary-panel" ink:if="{{flowState === 'ready' || flowState === 'loading' || flowState === 'error' || flowState === 'blocked'}}">
      <text class="label">ASSESSMENT</text>
      <text class="summary">{{summary}}</text>
      <view class="risk-row">
        <text class="label">RISK</text>
        <text class="risk risk-{{risk}}">{{risk}}</text>
      </view>
    </view>

    <view class="step-panel" ink:if="{{flowState === 'loading' || flowState === 'step'}}">
      <view class="step-header">
        <text class="label">NEXT ACTION</text>
        <view class="step-meta">
          <text class="step-risk risk-{{risk}}">RISK {{risk}}</text>
          <text class="step-count" ink:if="{{steps.length}}">{{currentStepIndex + 1}}/{{steps.length}}</text>
        </view>
      </view>
      <text class="step-title">{{currentStepTitle}}</text>
      <text class="step-detail">{{currentStepDetail}}</text>
      <text class="step-prompt">{{currentStepPrompt}}</text>
    </view>

    <view class="complete-panel" ink:if="{{flowState === 'complete'}}">
      <text class="label">SERVICE RECORD</text>
      <text class="step-title">Repair sequence complete</text>
      <text class="step-detail">All planned actions were explicitly confirmed on the glasses.</text>
      <text class="risk">{{risk}} RISK REMAINS VISIBLE</text>
    </view>

    <view class="evidence-panel" ink:if="{{flowState === 'step'}}">
      <text class="label">EVIDENCE</text>
      <text class="evidence-title">{{evidenceTitle}}</text>
      <text class="evidence-source">{{evidenceSource}}</text>
    </view>

    <text class="next-action">{{nextAction}}</text>
    <text class="error" ink:if="{{error}}">{{error}}</text>

    <view class="controls" role="navigation">
      <button class="primary" bindtap="startRepair" ink:if="{{flowState === 'ready' || flowState === 'error'}}">START REPAIR</button>
      <button class="primary" bindtap="confirmStep" ink:if="{{flowState === 'step'}}">CONFIRM STEP</button>
      <button class="primary" bindtap="resetFlow" ink:if="{{flowState === 'complete'}}">NEW CASE</button>
      <button class="primary" bindtap="resetFlow" ink:if="{{flowState === 'blocked'}}">NEW CASE</button>
    </view>

  </view>
</page>

<style>
  page {
    background-color: #07110a;
    color: #40ff5e;
  }

  .screen {
    display: flex;
    flex-direction: column;
    padding: 8px 16px;
    gap: 6px;
    min-height: 328px;
    height: 328px;
    overflow: hidden;
  }

  .topbar,
  .status-line,
  .step-header,
  .risk-row {
    display: flex;
    flex-direction: row;
    align-items: center;
  }

  .topbar {
    justify-content: space-between;
    border-bottom: 1px solid #2d6d39;
    padding-bottom: 8px;
  }

  .brand {
    font-size: 18px;
    font-weight: bold;
    letter-spacing: 1px;
  }

  .device,
  .provider,
  .input-hint,
  .debug-input,
  .label,
  .evidence-source {
    color: #9ebca4;
    font-size: 10px;
  }

  .status-line {
    gap: 6px;
  }

  .status-dot,
  .status {
    color: #40ff5e;
    font-size: 12px;
    font-weight: bold;
  }

  .provider {
    margin-left: auto;
  }

  .case-panel,
  .summary-panel,
  .step-panel,
  .evidence-panel,
  .complete-panel {
    display: flex;
    flex-direction: column;
    gap: 4px;
    border: 1px solid #2d6d39;
    border-radius: 4px;
    padding: 7px;
  }

  .case-panel {
    background-color: #0b1d10;
  }

  .case-title,
  .step-title {
    color: #40ff5e;
    font-size: 16px;
    font-weight: bold;
  }

  .symptom,
  .summary,
  .step-detail,
  .next-action {
    color: #d4f2d8;
    font-size: 12px;
    line-height: 15px;
  }

  .risk-row {
    justify-content: space-between;
    margin-top: 4px;
  }

  .risk {
    color: #40ff5e;
    font-size: 13px;
    font-weight: bold;
  }

  .risk-UNASSESSED,
  .risk-UNKNOWN {
    color: #9ebca4;
  }

  .step-panel {
    border-width: 2px;
    border-color: #40ff5e;
  }

  .complete-panel {
    border-width: 2px;
    border-color: #40ff5e;
  }

  .step-header {
    justify-content: space-between;
  }

  .step-meta {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 8px;
  }

  .step-risk {
    color: #40ff5e;
    font-size: 10px;
    font-weight: bold;
  }

  .step-count {
    color: #40ff5e;
    font-size: 11px;
  }

  .step-prompt {
    color: #40ff5e;
    font-size: 12px;
    font-weight: bold;
  }

  .evidence-item {
    display: flex;
    flex-direction: column;
    gap: 2px;
    border-top: 1px solid #2d6d39;
    padding-top: 6px;
  }

  .evidence-title {
    color: #d4f2d8;
    font-size: 12px;
  }

  .error {
    color: #ffb347;
    font-size: 11px;
    line-height: 15px;
    max-height: 15px;
    overflow: hidden;
  }

  .controls {
    display: flex;
    flex-direction: row;
    margin-top: 2px;
  }

  button.primary {
    flex: 1;
    border: 1px solid #40ff5e;
    border-radius: 4px;
    background-color: #123b1b;
    color: #40ff5e;
    font-size: 14px;
    font-weight: bold;
    padding: 8px 10px;
    text-align: center;
  }

  button.primary:focus {
    border-color: #d4f2d8;
    background-color: #40ff5e;
    color: #07110a;
  }

</style>

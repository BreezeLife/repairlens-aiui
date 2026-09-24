<script type="application/json" def>
{
  "navigationBarTitleText": "RepairLens"
}
</script>

<script setup>
import wx from 'wx';

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
    summary: 'Describe an equipment issue, then confirm one safe action at a time.',
    risk: 'UNASSESSED',
    nextAction: 'Ready to load a repair plan.',
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
  };
}

function normalizePlan(plan) {
  const source = plan && typeof plan === 'object' ? plan : DEMO_PLAN;
  const rawSteps = Array.isArray(source.steps) && source.steps.length ? source.steps : DEMO_PLAN.steps;
  const steps = rawSteps.slice(0, 6).map((step, index) => ({
    id: String(step.id || `step-${index + 1}`),
    title: String(step.title || `Step ${index + 1}`),
    detail: String(step.detail || 'Follow the verified procedure.'),
    confirmPrompt: String(step.confirmPrompt || 'Confirm this action is complete?'),
  }));
  return {
    provider: source.provider || 'unknown',
    equipment: source.equipment || DEMO_PLAN.equipment,
    summary: source.summary || DEMO_PLAN.summary,
    risk: source.risk || 'UNKNOWN',
    nextAction: source.nextAction || DEMO_PLAN.nextAction,
    steps,
    evidence: Array.isArray(source.evidence) && source.evidence.length
      ? source.evidence.slice(0, 3)
      : DEMO_PLAN.evidence,
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
    });

    const app = getApp();
    const configuredBaseUrl = app && app.globalData && app.globalData.apiBaseUrl
      ? app.globalData.apiBaseUrl
      : 'http://127.0.0.1:8787';
    const baseUrl = configuredBaseUrl.replace(/\/+$/, '');

    fetch(`${baseUrl}/api/repair/analyze`, {
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
      .then((plan) => this.applyPlan(normalizePlan(plan)))
      .catch((error) => {
        const fallback = normalizePlan(DEMO_PLAN);
        this.setData({
          error: `Using offline plan: ${error && error.message ? error.message : 'network unavailable'}`,
        });
        this.applyPlan(fallback, true);
      });
  },

  applyPlan(plan, usedFallback = false) {
    const stepState = getCurrentStep(plan, 0);
    this.setData({
      flowState: 'step',
      status: usedFallback ? 'OFFLINE PLAN' : 'PLAN READY',
      summary: plan.summary,
      risk: plan.risk,
      nextAction: plan.nextAction,
      steps: plan.steps,
      currentStepIndex: 0,
      ...stepState,
      evidence: plan.evidence,
      evidenceTitle: plan.evidence[0] && plan.evidence[0].title ? plan.evidence[0].title : 'Source available',
      evidenceSource: plan.evidence[0] && plan.evidence[0].source ? plan.evidence[0].source : 'Unspecified source',
      provider: usedFallback ? 'demo-fallback' : plan.provider,
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

    <view class="case-panel" ink:if="{{flowState === 'ready' || flowState === 'loading' || flowState === 'error'}}">
      <text class="label">CASE</text>
      <text class="case-title">{{equipment}}</text>
      <text class="symptom">{{symptom}}</text>
    </view>

    <view class="summary-panel" ink:if="{{flowState === 'ready' || flowState === 'loading' || flowState === 'error'}}">
      <text class="label">ASSESSMENT</text>
      <text class="summary">{{summary}}</text>
      <view class="risk-row">
        <text class="label">RISK</text>
        <text class="risk risk-{{risk}}">{{risk}}</text>
      </view>
    </view>

    <view class="step-panel" ink:if="{{flowState === 'loading' || flowState === 'step'}}">
      <view class="step-header">
        <text class="label">NEXT VERIFIED ACTION</text>
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
    padding: 8px 12px;
    gap: 6px;
    min-height: 328px;
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

</style>

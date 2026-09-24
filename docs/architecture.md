# RepairLens architecture

```text
ROKID Glasses
  AIUI 0.17 Page
    voice wakeup starts / Enter or tested hardware action confirms
        |
        | HTTPS POST /api/repair/analyze
        v
Nebius Serverless Endpoint
  Token Factory -> NVIDIA open source model (Nemotron target)
  optional Tavily grounding
        |
        v
repair plan + risk + evidence + confirmation prompts
```

## Product contract

The glasses client does not render a long chat transcript. It renders one short verified action at a time. The backend returns a stable contract:

```json
{
  "equipment": "HVAC condenser",
  "summary": "...",
  "risk": "MEDIUM",
  "nextAction": "...",
  "steps": [
    {
      "id": "isolate",
      "title": "Isolate power",
      "detail": "...",
      "confirmPrompt": "Power isolated and fan stopped?"
    }
  ],
  "evidence": [
    {
      "title": "Service manual",
      "source": "manual.pdf#page=3",
      "excerpt": "..."
    }
  ]
}
```

## Fallback rule

The Android/CXR-S client is a transport and device capability fallback. It must call the same backend contract and cannot silently add a second repair policy.

## Capability evidence boundary

`onVoiceWakeup`, `onKeyDown`, and `onKeyUp` are the documented Page events used by this source. `GlobalHook`, camera input, `_current`, and `_blank` host behavior remain unverified until the exact ROKID model and AIUI Studio/device session are available. The source does not claim those capabilities are working.

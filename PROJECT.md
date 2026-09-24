# RepairLens

## Vision

RepairLens is a hands-free field-service assistant for ROKID Glasses. It helps a technician understand an equipment issue, retrieve the right procedure, follow the next safe step, and produce a verifiable service record.

The glasses are the primary interaction surface. Cloud inference and long-running work run on Nebius using NVIDIA open source models. The project must remain importable from GitHub and reproducible by another builder.

## Primary Technology Decision

### Primary path: AIUI Agent

- Target: stable AIUI `0.17.0` unless the target host is explicitly capability-tested for another version.
- Agent authoring reference: use the official [ROKID AIUI Tools Skills](https://js.rokid.com/AIUI/tools/skills?version=0.17.0&lang=zh-CN) page and enable/download its `AIUI Dev` Skill before agent implementation.
- Authoring: complete AIUI Studio-importable project using `app.json`, `app.js`, `.ink` Pages, and shared WXSS where needed.
- Surfaces: the source currently provides one importable Page; `_current` compact status and `_blank` full-workflow host behavior remain a capability-validation task, not a source claim.
- Device target: ROKID Glasses; the exact hardware model remains a validation input.
- Device input: documented AIUI Page voice wakeup, key events, and only capability-tested head gestures.
- Visual system: use the AIUI monochrome-green glasses guidance; do not conflate the AIUI 480x352 runtime canvas with older 480x640 optical guidance until the target glasses/runtime is identified.
- Required audit: include `aiui-audit-claims.json` and complete the AIUI fingerprint, inventory, strict validation, and evidence-matrix workflow.
- The official web Skill assists authoring; it does not replace source inspection, strict validation, Studio simulation, or physical ROKID Glasses evidence.

### Cloud path

- Model serving: NVIDIA Nemotron or another eligible NVIDIA open source model through Nebius Token Factory.
- Real-time API: Nebius Serverless Endpoint.
- Long-running processing: Nebius Serverless Jobs.
- Optional research grounding: Tavily, with source links shown in the repair result.
- Keep secrets and provider credentials out of the repository.

### Fallback path: standalone glasses Android

Use only when a required capability is unavailable or incomplete in AIUI (for example, a required device bridge, camera behavior, or system-level input). Use Kotlin Android Go/YodaOS-Sprite with:

- `minSdk >= 28`
- Rokid Maven repository
- `com.rokid.cxr:cxr-service-bridge:1.0-20250519.061355-45`
- CXR-S status monitoring and versioned Caps messages
- reserved system input coexistence and an explicit exit route

The fallback client must preserve the same backend API and RepairLens interaction model so it can replace the AIUI client without changing the product contract.

## Product Boundary

The first demo focuses on one repair domain and one closed workflow:

1. technician states the equipment problem;
2. RepairLens retrieves grounded procedures;
3. the glasses show one short next step at a time;
4. technician confirms completion with a deliberate validated key/button action;
5. the Page records the confirmed in-session sequence with evidence and unresolved risks. Durable export remains outside v0.

Camera input is provisional until the exact Rokid hardware exposes a supported AIUI camera capability. Voice, text, and a phone-companion upload are valid fallbacks.

## Repository and GitHub Contract

- GitHub is the source of truth and must be synchronized at every meaningful milestone.
- Recommended repository layout: `aiui/` is the explicitly named AIUI Studio import directory; `backend/`, `android-fallback/`, `docs/`, and `evals/` live beside it.
- The public repository must include an open-source license, README setup instructions, device setup notes, Nebius configuration, NVIDIA model usage, and reproducible evaluation steps.

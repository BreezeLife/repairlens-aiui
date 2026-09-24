# Project Memory

## Durable Decisions

- The project must stay synchronized with a public GitHub repository.
- Every meaningful implementation milestone should be committed and pushed after the repository and remote are available.
- The repository must include an open-source license and a README with setup and run instructions for hackathon submission.
- ROKID Glasses are the required target device family, not an optional future integration; the exact model is still to be confirmed.
- The product should expose a glasses-native workflow using the Rokid display and system input, with cloud inference delegated to Nebius/NVIDIA services.
- The first product candidate is RepairLens, a hands-free field-service assistant.
- Technology priority is AIUI Agent first; standalone Kotlin Android on YodaOS-Sprite with CXR-S is the fallback only for capabilities AIUI cannot complete.
- Default AIUI target is stable `0.17.0`; do not add 0.18-only Widgets or Agent Workers without explicit host capability evidence.
- Use the official ROKID AIUI Tools `AIUI Dev` Skill at `https://js.rokid.com/AIUI/tools/skills?version=0.17.0&lang=zh-CN` for Agent authoring before falling back to the local Android path.
- Cloud baseline is Nebius Token Factory with an eligible NVIDIA open source model, plus Serverless Endpoints/Jobs as needed.

## Current Constraint

- The workspace now has a local Git repository on `main`; no GitHub remote is configured yet.
- Rokid hardware, Android project scaffolding, and device credentials are not available in the current workspace yet.
- The exact Rokid glasses model and AIUI host/runtime are still unknown, so camera availability and final viewport must remain provisional until tested.
- The official web Skill has been located, but it has not yet been enabled against a RepairLens workspace.
- The local AIUI/backend source and deterministic test contract are implemented. The Page records confirmations only for the current session; durable export is not implemented in v0.
- `GlobalHook`, camera, `_current`/`_blank` host behavior, Nebius deployment, Studio import, physical-device input, and GitHub remote remain external evidence gates.

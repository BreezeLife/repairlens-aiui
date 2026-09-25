# Findings & Decisions

## Requirements
- Build RepairLens for ROKID Glasses.
- Use AIUI Agent first; fall back to standalone Android/YodaOS-Sprite only for missing AIUI capabilities.
- Use Nebius Token Factory or AI Cloud and an eligible NVIDIA open source model.
- Keep the project synchronized with GitHub and include an open-source license and README.
- Produce a working demo, public code, and a short demo video for the hackathon.

## Research Findings
- The local AIUI guidance sets stable default compatibility to AIUI `0.17.0` and requires a complete Studio-importable project, not only an AIX package.
- AIUI project roots need `AGENTS.md`, `app.json`, an application entry, declared Pages, and resources; a GitHub subdirectory can be the explicit import root.
- AIUI supports documented Page voice wakeup, key events, HTTPS, and WebSocket paths; exact host/device behavior still needs Studio and physical-glasses evidence.
- The AIUI design guidance distinguishes the 0.17 480x352 runtime/reference canvas from older 480x640 optical guidance. These must not be conflated.
- The official ROKID AIUI Tools page exposes an `AIUI Dev` Skill that must be downloaded into the browser-local resource layer before enabling it.
- Standalone-glasses fallback guidance requires Android Go/YodaOS-Sprite, `minSdk >= 28`, ROKID Maven, and CXR-S bridge integration.
- Official Page events document `onKeyDown`, `onKeyUp`, `onVoiceWakeup`; ROKID Glasses commonly expose `Backspace`, `ArrowUp`, `ArrowDown`, `Enter`, and `GlobalHook`.
- Official `.ink` SFC samples use `<script def>`, `<script setup>`, `<page>`, and `<style>` blocks, with `bindtap` for buttons.

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| AIUI `.ink` Pages first | Lowest-weight native path for ROKID glasses and directly importable by AIUI Studio |
| `_current` and `_blank` UI states | Host targets have different constraints, but exact behavior remains unverified and is not claimed by the source |
| Text/voice first, camera optional | Avoids inventing camera support before the model and host are identified |
| Backend API returns grounded steps and evidence | Repair guidance must be auditable and safe rather than free-form chat |
| Local mock adapter mirrors Nebius contract | Enables deterministic testing without leaking API keys or requiring cloud access |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
| GitHub remote was initially unavailable | Configured `origin` and verified the public `main` commit matches the local branch |
| No hardware or Studio runtime | Build source and static/local verification, mark external evidence blocked |
| Parallel GitHub Raw fetch timed out for several files | Use the successfully fetched official structure/event documents and avoid repeating the same concurrent fetch pattern |

## Resources
- ROKID AIUI Tools Skill: https://js.rokid.com/AIUI/tools/skills?version=0.17.0&lang=zh-CN
- AIUI stable source snapshot: https://github.com/yodaos-project/AIUI/tree/88e70bb0382525c1a93ef077c2401dcc31a273ce
- AIUI project structure: https://github.com/yodaos-project/AIUI/blob/88e70bb0382525c1a93ef077c2401dcc31a273ce/documentation/0-guide/structure.md
- AIUI official samples: https://github.com/yodaos-project/AIUI/tree/88e70bb0382525c1a93ef077c2401dcc31a273ce/samples
- Hackathon page: https://nebiusglobalaihackathon.devpost.com/

## Confidence Check
- No duplicate implementation: PASS (one AIUI client and one backend contract)
- Architecture compliance: PASS (AIUI 0.17 primary, Android fallback isolated)
- Official documentation verified: PASS (local AIUI/Rokid guidance and official source links reviewed)
- Working OSS reference: PASS (official AIUI project structure and samples identified)
- Root cause clarity: PASS (local implementation is complete; remaining blockers are external hardware/runtime and Nebius deployment)
- Local verification: PASS (`npm test`, 15 tests; root static validator)
- External verification: BLOCKED (AIUI Studio, physical device, Nebius deployment); GitHub `main` content is synchronized and verified through the Git Data API
- Confidence: 92% for local source contract; device behavior remains unverified

## Implementation Findings
- The AIUI Page uses `onVoiceWakeup` only to start the case. A wakeup event while a step is active cannot advance it; the user must use the validated button/Enter path.
- The backend rejects missing `equipment`/`symptom` with 422, rejects non-JSON/oversized requests, limits model field lengths, and falls back when model JSON lacks usable evidence.
- The completion state records explicit confirmations in the Page session. Durable service-record export is intentionally outside v0 and is called out in the UI/docs.
- `.env` loading is opt-in through `npm --prefix backend run start:env` on Node 20.6+; the default start path remains dependency-free demo mode.

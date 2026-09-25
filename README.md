# RepairLens

RepairLens is a hands-free field-service assistant for ROKID Glasses. A technician receives grounded repair steps, confirms each action with a deliberate button or key action, and gets an in-session service record state.

The primary client is an AIUI 0.17 project importable into AIUI Studio. The backend runs locally for deterministic demos and can switch to a Nebius Token Factory or Nebius Serverless Endpoint using an OpenAI-compatible chat completion API. An Android/YodaOS-Sprite fallback boundary is documented under `android-fallback/` and is intentionally not activated until an AIUI capability gap is proven.

## Repository map

```text
aiui/                 AIUI Studio import root for the glasses client
backend/              Local adapter and Nebius-compatible repair API
android-fallback/     CXR-S fallback contract and activation notes
docs/                 Architecture, device validation, and demo script
evals/                Evaluation notes and future fixtures
PROJECT.md            Product vision and technical decisions
MEMORY.md             Durable project constraints
TASKS.md              Current work queue
```

## Quick start

Requirements: Node.js 18+ for the local demo backend. No runtime dependency installation is required.

```bash
npm test
npm --prefix backend start
```

The local API listens on `http://127.0.0.1:8787` by default. Test it with:

```bash
curl -sS -X POST http://127.0.0.1:8787/api/repair/analyze \
  -H 'content-type: application/json' \
  -d '{"equipment":"HVAC condenser","symptom":"Fan starts, then stops after two minutes"}'
```

## AIUI Studio import

Import the `aiui/` directory as the AIUI project root. The project targets stable AIUI `0.17.0` and uses one declared Page:

```text
aiui/
├── AGENTS.md
├── app.json
├── app.js
├── app.wxss
├── aiui-audit-claims.json
└── pages/home/index.ink
```

The AIUI Page defaults to an offline demo plan if the configured API cannot be reached. The v0 source uses a fixed HVAC demonstration case because AIUI 0.17 voice wakeup exposes an event, not a proven speech-transcript contract; bind a validated transcript or companion input before presenting free-form issue capture.
The Page labels this state `OFFLINE PLAN`, times out a repair request after 14 seconds, ignores late responses after a reset, and bounds model text before rendering it into the 480x352 viewport.

## Nebius configuration

Copy `backend/.env.example` to `backend/.env` and set:

- `NEBIUS_API_URL`: full OpenAI-compatible chat completions URL
- `NEBIUS_API_KEY`: secret token, never commit it
- `NEBIUS_MODEL`: eligible NVIDIA open source model served by Token Factory

Without these values, the backend deliberately returns a deterministic demo plan so the workflow remains testable.
The offline repair sequence applies only to the documented HVAC condenser symptom. Other cases return `actionable: false` with no repair steps until an equipment-specific procedure is available.

The regular `npm --prefix backend start` command uses process environment variables. To load a local `.env` file, use Node 20.6+:

```bash
npm --prefix backend run start:env
```

For a device or remote endpoint, set `HOST=0.0.0.0` and replace `aiui/app.js`'s loopback URL with an HTTPS endpoint reachable from the glasses. `127.0.0.1` refers to the device itself when the Page runs on glasses.

## ROKID device path

AIUI is the primary path. Validate the AIUI Page in Studio and on the target ROKID Glasses before activating the Android fallback. The fallback contract and CXR-S requirements are documented in `android-fallback/README.md`.

## GitHub handoff

The public repository must keep the `aiui/` directory importable, include this MIT license, and document the exact branch/ref used for AIUI Studio import. Commit and push each meaningful milestone once a Git remote is configured.

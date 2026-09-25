# Device validation checklist

This checklist separates source-level checks from evidence that requires AIUI Studio or a physical ROKID device. The latter must not be marked passed from static inspection.

| Gate | Current status | Evidence needed |
|------|----------------|-----------------|
| AIUI 0.17 project structure | PASS | Root validator and source tree |
| AIUI Studio import | BLOCKED | Studio import log or screenshot |
| AIUI Web simulation | PASS | AIX CLI 0.8.2 `preview --dev --launch`; Ink runtime initialized a 480x352 Page and rendered the RepairLens canvas |
| 480x352 Page rendering | PASS | Playwright capture from the AIX Web simulation; non-empty canvas at `/tmp/repairlens-live-enter-1.png` |
| Offline/timeout recovery | PASS | Simulated request failure and stalled request both reached `OFFLINE PLAN` with the confirmation action still visible |
| Long-response layout | PASS | Simulated oversized provider fields were compacted and the fixed 480x352 confirmation control remained visible |
| Voice wakeup event | BLOCKED | Target-device event log |
| Enter key confirmation | BLOCKED | Target-device event log |
| `GlobalHook` confirmation | BLOCKED | Exact-model capability evidence |
| Camera input | BLOCKED | Exact-model AIUI camera evidence |
| `_current` / `_blank` host targets | BLOCKED | Host/runtime behavior evidence |
| Nebius endpoint | BLOCKED | Deployment URL and health response |
| GitHub remote and push | PASS | GitHub `main` content tree matches the local delivery tree; the ref and recursive blob list were verified through the Git Data API |

Before a real-device demo, record the exact glasses model, AIUI host/runtime version, API URL, and the captured input/rendering evidence here or in a dated evidence bundle. The Android/CXR-S fallback stays inactive until one of the AIUI capability gates is proven unavailable.

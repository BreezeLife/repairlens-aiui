# Device validation checklist

This checklist separates source-level checks from evidence that requires AIUI Studio or a physical ROKID device. The latter must not be marked passed from static inspection.

| Gate | Current status | Evidence needed |
|------|----------------|-----------------|
| AIUI 0.17 project structure | PASS | Root validator and source tree |
| AIUI Studio import | BLOCKED | Studio import log or screenshot |
| 480x352 Page rendering | BLOCKED | Studio simulation or device capture |
| Voice wakeup event | BLOCKED | Target-device event log |
| Enter key confirmation | BLOCKED | Target-device event log |
| `GlobalHook` confirmation | BLOCKED | Exact-model capability evidence |
| Camera input | BLOCKED | Exact-model AIUI camera evidence |
| `_current` / `_blank` host targets | BLOCKED | Host/runtime behavior evidence |
| Nebius endpoint | BLOCKED | Deployment URL and health response |
| GitHub remote and push | PASS | `origin` points to the public repository and `main` matches the remote commit |

Before a real-device demo, record the exact glasses model, AIUI host/runtime version, API URL, and the captured input/rendering evidence here or in a dated evidence bundle. The Android/CXR-S fallback stays inactive until one of the AIUI capability gates is proven unavailable.

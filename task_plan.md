# Task Plan: Build RepairLens AIUI project

## Goal
Create a GitHub-ready RepairLens prototype for ROKID Glasses, with AIUI 0.17 as the primary client, a Nebius/NVIDIA-compatible backend contract, and an Android/CXR-S fallback boundary documented for capabilities AIUI cannot provide.

## Current Phase
Phase 5

## Phases

### Phase 1: Requirements & Discovery
- [x] Capture product, hackathon, ROKID, AIUI, and GitHub requirements
- [x] Read local AIUI and standalone-glasses development guidance
- [x] Record findings and confidence assessment
- **Status:** complete

### Phase 2: Planning & Structure
- [x] Define AIUI-first architecture and fallback boundary
- [x] Define importable repository layout and backend contract
- [x] Create persistent project planning files
- **Status:** complete

### Phase 3: Implementation
- [x] Build the AIUI 0.17 source project
- [x] Build a local deterministic backend adapter and Nebius deployment contract
- [x] Add GitHub/README/license/device documentation
- [x] Add Android fallback boundary only where needed
- **Status:** complete

### Phase 4: Testing & Verification
- [x] Run static project validation and repository tests
- [ ] Run AIUI fingerprint/inventory/strict validation if scripts are available
- [x] Record unavailable Studio/device/GitHub gates as blocked, never passed
- **Status:** complete for available local gates; external runtime gates blocked

### Phase 5: Delivery
- [x] Review deliverables and update project records
- [x] Report exact paths, validation results, and remaining external gates
- **Status:** complete

## Key Questions
1. Which ROKID Glasses model and AIUI host/runtime are available for device evidence?
2. Which repair domain gives the clearest 3-minute demo with safe, grounded procedures?
3. Which AIUI capability gaps, if any, force use of the Android/CXR-S fallback?

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| AIUI 0.17 is the primary client | User requested AIUI Agent first and 0.17 is the stable baseline |
| RepairLens starts with one closed repair workflow | A narrow workflow is more testable and demoable than a generic assistant |
| Nebius adapter uses OpenAI-compatible HTTP | Keeps local tests deterministic while allowing Token Factory/Endpoint configuration |
| Camera remains optional in v0 | Exact ROKID hardware and AIUI camera support are not yet verified |
| GitHub project root is `aiui/` | AIUI Studio can import an explicit subdirectory while backend/docs remain in the repository |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| Workspace has no Git repository or remote | 1 | Continue with source creation and document GitHub setup as an external gate |
| No ROKID hardware/Studio session available | 1 | Keep Studio/device evidence blocked and use static/local validation only |
| Local sandbox denied loopback test-port binding | 1 | Test the exported HTTP handler with in-memory request/response objects; keep runtime listen as an external smoke gate |

## Notes
- Never claim AIUI Studio, physical-device, package, or GitHub publication success without executing that gate.
- Update `findings.md` after each research batch and `progress.md` after each phase or error.

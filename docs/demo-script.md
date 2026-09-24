# RepairLens three-minute demo

## 0:00-0:20: Problem

Show a technician at an HVAC condenser. Say: "The fan starts, then stops after two minutes." Explain that hands-free work needs a short, safe next action rather than a chat transcript.

## 0:20-0:50: Start on ROKID Glasses

Open RepairLens. Use the START button, `Enter`, or the documented voice wakeup event. The Page shows `ANALYZING` while the Agent request is prepared. Do not present `GlobalHook` as working until the target device has been tested.

## 0:50-1:25: Grounded plan

Show the summary, risk level, provider, and evidence source. Mention that the same endpoint can use an NVIDIA open source model served through Nebius Token Factory; the local demo fixture keeps the flow reproducible.

## 1:25-2:20: Hands-free confirmation

Confirm each step with the button or `Enter`. A voice wakeup while a step is active is recorded as wakeup only and does not advance the step without a deliberate hardware/button confirmation. The glasses show one action at a time and keep the risk visible.

## 2:20-2:45: Completion record

Complete the final step. The Page changes to `RECORDED` and shows the confirmed in-session service record state. Durable export is outside this v0 source boundary.

## 2:45-3:00: Architecture

Show the GitHub repository, the `aiui/` import root, the Nebius endpoint contract, and the AIUI-first / Android fallback boundary.

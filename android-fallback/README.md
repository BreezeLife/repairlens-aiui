# Android fallback boundary

This directory is intentionally a boundary document, not the primary client. Activate it only after an AIUI 0.17 capability test proves that RepairLens cannot complete a required ROKID Glasses interaction.

## Planned stack

- Kotlin + Android Go / YodaOS-Sprite
- `minSdk >= 28`
- Rokid Maven repository: `https://maven.rokid.com/repository/maven-public/`
- CXR-S bridge: `com.rokid.cxr:cxr-service-bridge:1.0-20250519.061355-45`
- 480x640 optical guidance only where confirmed by the target device; do not treat it as the AIUI runtime canvas

## Activation criteria

Use this path only for a concrete AIUI failure such as:

- required CXR-S device messaging unavailable in AIUI;
- target-model system input unavailable in AIUI;
- required camera lifecycle unsupported in the tested AIUI host.

The fallback must use the same `POST /api/repair/analyze` backend contract as the AIUI client. Do not fork product logic between clients.

## Required device evidence

1. Enable ADB in the Rokid AI mobile app.
2. Connect with the dedicated development/data cable.
3. Verify the target app on the glasses and capture `adb logcat` output.
4. Preserve reserved system actions and provide an explicit exit route.


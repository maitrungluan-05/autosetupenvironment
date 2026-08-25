# DevSetup Architecture Documentation

## Core Design Principles

1. **Safety & Idempotency**: Inspect system status before applying any state changes. Never uninstall, overwrite, or downgrade pre-existing developer tools without explicit user confirmation.
2. **Minimal Administrative Privileges**: DevSetup runs entirely under normal User scope. Elevation (UAC) is requested dynamically only for packages specifying `"requiresAdmin": true`.
3. **Modular & Preset-driven**: Shared pipeline across all environment handlers (`Java`, `Python`, `Node.js`, `C/C++`, `Go`, `Rust`, `Web`, `DevOps`).
4. **Environment Real-time Refresh**: Process environment variables (`PATH`, `JAVA_HOME`) are reloaded into the active process memory after Winget installation to verify binaries without forcing terminal restarts.
5. **Machine-Readable Outputs**: `devsetup doctor --json` outputs clean JSON data without ANSI formatting to stdout for automation / CI pipelines.

---

## Component Architecture

```
                               ┌─────────────────────────┐
                               │       devsetup.ps1      │
                               └────────────┬────────────┘
                                            │
                               ┌────────────▼────────────┐
                               │       src/main.ps1      │
                               └────────────┬────────────┘
                                            │
               ┌────────────────────────────┼────────────────────────────┐
               │                            │                            │
   ┌───────────▼───────────┐    ┌───────────▼───────────┐    ┌───────────▼───────────┐
   │    src/core/*.ps1     │    │  src/environments/*.  │    │   src/commands/*.ps1  │
   ├───────────────────────┤    ├───────────────────────┤    ├───────────────────────┤
   │ platform.ps1          │    │ java.ps1              │    │ doctor.ps1            │
   │ logger.ps1            │    │ python.ps1            │    │ update.ps1            │
   │ ui.ps1                │    │ node.ps1              │    │ list.ps1              │
   │ config.ps1            │    │ cpp.ps1               │    │ help.ps1              │
   │ detector.ps1          │    │ go.ps1                │    │ install.ps1           │
   │ versions.ps1          │    │ rust.ps1              │    │                       │
   │ winget.ps1            │    │ web.ps1               │    │                       │
   │ installer.ps1         │    │ devops.ps1            │    │                       │
   │ verifier.ps1          │    └───────────────────────┘    └───────────────────────┘
   │ environment.ps1       │
   │ process.ps1           │
   │ paths.ps1             │
   └───────────────────────┘
```

---

## Pipeline Execution Sequence

```
1. Load Config & Defaults (config/environments.json)
2. Assert Platform Requirements (Windows NT, Winget)
3. Detect Current Package Status (where.exe, Get-Command, Version Parser)
4. Compare Versions (SemVer Engine)
5. Generate Installation Plan ([KEEP], [INSTALL], [UPGRADE], [REPAIR])
6. User Confirmation / --yes / --dry-run
7. Execute Plan via Winget Engine
8. Refresh Process Environment (User + System PATH)
9. Perform Smoke Test Verification
10. Generate Final Summary Report
```

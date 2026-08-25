# DevSetup

> **Windows Development Environment Manager**  
> A production-ready, modular, safe, and config-driven PowerShell CLI tool for Windows developers.

[![Windows](https://img.shields.io/badge/OS-Windows-blue.svg)](https://microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-blue.svg)](https://microsoft.com/powershell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## ðŸŒŸ Overview

**DevSetup** automates the inspection, setup, verification, and maintenance of developer environments on Windows. Whether setting up a freshly installed Windows machine or maintaining an existing workstation, DevSetup provisions tools safely without breaking existing configurations or uninstalling existing software.

---

## âœ¨ Features

* **ðŸ›¡ï¸ Safe & Non-destructive**: Never uninstalls or overwrites existing developer tools. Detects installed versions and marks them as `[KEEP]`.
* **ðŸ” Idempotent Engine**: Re-running DevSetup only installs missing or outdated components.
* **ðŸ” Strict Elevation Control**: Runs without Administrator privileges by default. Elevation (UAC) is requested only when a specific package requires it (e.g. Visual Studio Build Tools).
* **âš¡ Environment Refreshing**: Automatically reloads `User` and `Machine` environment variables (`PATH`, `JAVA_HOME`) into the current process so binaries are instantly verifiable without restarting PowerShell.
* **ðŸ” Robust Detection**: Distinguishes JRE vs. JDK, ignores Microsoft Store execution redirects, and parses complex SemVer/numeric version strings.
* **ðŸ§ª Machine-Readable Diagnostics**: `devsetup doctor --json` outputs clean JSON data for automated pipelines.
* **ðŸ“‹ Dry Run Mode**: Preview installation plans (`--dry-run`) without modifying system state.
* **ðŸ“¦ Config-Driven Architecture**: Easily extend environments and Winget package definitions in JSON configuration files.

---

## ðŸš€ Quick Start

### Secure Installation (Recommended)

1. Download the latest release package and SHA256 checksum from Releases:
   - `DevSetup-v0.9.0-rc.1.zip`
   - `DevSetup-v0.9.0-rc.1.zip.sha256`

2. Verify SHA256 checksum in PowerShell:

```powershell
(Get-FileHash -Path .\DevSetup-v0.9.0-rc.1.zip -Algorithm SHA256).Hash -eq (Get-Content .\DevSetup-v0.9.0-rc.1.zip.sha256).Split(' ')[0]
```

3. Extract and run:

```powershell
Expand-Archive -Path .\DevSetup-v0.9.0-rc.1.zip -DestinationPath $env:LOCALAPPDATA\DevSetup -Force
& $env:LOCALAPPDATA\DevSetup\devsetup.ps1
```

### Quick Bootstrap

```powershell
irm https://raw.githubusercontent.com/devsetup/devsetup/v0.9.0-rc.1/bootstrap.ps1 | iex
```

---

## ðŸŽ® Interactive CLI

Run `devsetup` without arguments to launch the interactive menu:

```text
========================================
               DevSetup
========================================

Windows Development Environment Manager

Select environment:

  [1] Java
  [2] Python
  [3] Node.js
  [4] C/C++
  [5] Go
  [6] Rust
  [7] Web Development
  [8] DevOps

  [A] All
  [D] Doctor
  [U] Update
  [H] Help
  [Q] Quit

Select:
```

---

## ðŸ’» CLI Commands & Options

```powershell
# Interactive Menu
devsetup

# Environment Commands
devsetup java
devsetup python
devsetup node
devsetup cpp
devsetup go
devsetup rust
devsetup web
devsetup devops

# All Environments Mode
devsetup all

# Diagnostics & Updates
devsetup doctor
devsetup update
devsetup update java

# Information
devsetup list
devsetup help
devsetup version
```

### CLI Options

| Flag | Description |
| :--- | :--- |
| `--dry-run` | Detects tools and displays installation plan without altering system state. |
| `--yes` | Suppresses confirmation prompts (ideal for CI/CD and automated setups). |
| `--verbose` | Displays detailed diagnostic logs during execution. |
| `--no-ide` | Skips optional IDE installations (e.g., IntelliJ IDEA, VS Code). |
| `--json` | Outputs machine-readable JSON for `devsetup doctor`. |

---

## ðŸ› ï¸ Supported Environments

| Environment | Included Packages | Default Version / Winget ID |
| :--- | :--- | :--- |
| **Java** | OpenJDK 21 LTS, Maven, Gradle, IntelliJ IDEA | `Microsoft.OpenJDK.21` |
| **Python** | Python 3.13, pip, virtualenv, VS Code | `Python.Python.3.13` |
| **Node.js** | Node.js LTS, npm, npx, pnpm, yarn | `OpenJS.NodeJS.LTS` |
| **C/C++** | VS Build Tools 2022, CMake, Ninja, LLVM/Clang | `Microsoft.VisualStudio.2022.BuildTools` |
| **Go** | Go Language Toolchain | `GoLang.Go` |
| **Rust** | Rustup, rustc, cargo | `Rustlang.Rustup` |
| **Web Preset** | Git, Node.js LTS, VS Code, GitHub CLI | Preset composition |
| **DevOps Preset**| Git, Docker Desktop, kubectl, Helm, Terraform, AWS/Azure CLI | Preset composition |

---

## ðŸ©º Doctor Command

Run system diagnostics across all environments:

```powershell
devsetup doctor
```

Output:

```text
========================================
             DevSetup Doctor
========================================

System
  [OK] Windows 11 (64-bit)
  [OK] PowerShell 7.4.2
  [OK] winget v1.29.290
  [OK] Internet Connection

Component            Current        Required       Status
--------------------------------------------------------------
Git                  2.50.1         >= 2.30.0      [OK]
JDK                  21.0.8         >= 21          [OK]
Maven                -              installed      [MISSING]
Node.js              22.14.0        >= 20.0.0      [OK]
Python               3.13.5         >= 3.10.0      [OK]

--------------------------------------------------------------
Health: 12 / 14 checks passed
Warnings: 0
Missing:  2
```

### JSON Doctor Output

```powershell
devsetup doctor --json
```

Output:

```json
{
  "healthy": false,
  "exitCode": 1,
  "system": {
    "Windows": true,
    "Winget": true
  },
  "summary": {
    "totalChecks": 14,
    "passed": 12,
    "warnings": 0,
    "missing": 2
  }
}
```

Exit Codes for `doctor`:
- `0`: All checks passed (Healthy)
- `1`: Warnings or optional components missing
- `2`: Required component missing or broken

---

## ðŸ§ª Testing

DevSetup contains a Pester test suite covering version parsing, config validation, detector logic, and mocked winget interactions:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run-tests.ps1
```

---

## ðŸ—ï¸ Release Build Process

Build release ZIP and SHA256 checksum artifacts:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-release.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify-release.ps1
```

---

## ðŸ—‘ï¸ Uninstalling DevSetup

To remove DevSetup from your system:

```powershell
Remove-Item -Path $env:LOCALAPPDATA\DevSetup -Recurse -Force
```

> [!NOTE]
> Uninstalling DevSetup removes the CLI tool itself. Developer tools installed through DevSetup (Java, Python, Node, Git, etc.) remain installed on your system.

---

## ðŸ“„ License

DevSetup is licensed under the [MIT License](LICENSE).

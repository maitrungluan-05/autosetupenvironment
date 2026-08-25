# Changelog

All notable changes to **DevSetup** will be documented in this file.

## [0.9.0-rc] - 2026-08-25

### Added
- Initial production release of **DevSetup CLI**.
- Interactive PowerShell CLI interface with colored formatting and fallback support.
- Core pipeline architecture: Config loading, Platform check, Detection engine, Version comparison engine, Winget wrapper, Installation manager, Process environment refresher, and Verifier.
- Support for reference Java 21 LTS environment (JDK vs JRE detection, JAVA_HOME validation).
- Support for Python (3.13 LTS, pip, virtualenv, ignoring MS Store aliases).
- Support for Node.js LTS (node, npm, npx, pnpm, yarn).
- Support for C/C++ (Visual Studio Build Tools 2022, CMake, Ninja, LLVM/Clang).
- Support for Go (`GoLang.Go`).
- Support for Rust (`Rustlang.Rustup`).
- Support for Web Development preset (Git, Node.js, VS Code, GitHub CLI).
- Support for DevOps preset (Git, Docker Desktop, kubectl, Helm, Terraform, AWS CLI, Azure CLI).
- `devsetup all` command with deduplicated package dependency resolution.
- `devsetup doctor` command with text and machine-readable `--json` output formats.
- `devsetup update` command for managed package updates.
- `--dry-run`, `--yes`, `--verbose`, `--no-ide` flags.
- Comprehensive Pester unit test suite with 100% pass rate.
- Release builder `scripts/build-release.ps1` and verification `scripts/verify-release.ps1` with SHA256 checksums.
- Secure, lightweight `bootstrap.ps1` installer.


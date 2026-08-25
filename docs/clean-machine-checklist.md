# DevSetup Clean-Machine Verification Checklist

> Run only in **Windows Sandbox** or a disposable Windows VM. Do not use this procedure on a developer workstation.

## Baseline
- [ ] Fresh Windows image is running.
- [ ] `winget --version` succeeds.
- [ ] DevSetup is not installed under `%LOCALAPPDATA%\DevSetup`.
- [ ] Capture baseline `PATH` and `JAVA_HOME`.
- [ ] Record whether Git is absent or pre-installed.
- [ ] Confirm Java is absent with `where.exe java` and `where.exe javac`.

## Bootstrap and Java
- [ ] Download DevSetup ZIP and `.sha256` from the pinned release.
- [ ] Verify the checksum before invoking bootstrap.
- [ ] Run the bootstrap script and confirm it stages, validates, and installs DevSetup.
- [ ] Run `devsetup doctor`.
- [ ] Run `devsetup java --dry-run`; confirm no environment variables or directories changed.
- [ ] Run `devsetup java`; approve normal package operations deliberately.
- [ ] Confirm `java -version` and `javac -version` report Java 21 or newer.
- [ ] Re-run `devsetup java`; confirm JDK action is `[KEEP]`, no duplicate PATH entry exists, and no environment value changes.

## Update and rollback
- [ ] Stage a valid newer release fixture and verify `devsetup self-update` installs only after confirmation.
- [ ] Stage a fixture with an intentionally incorrect SHA256 file.
- [ ] Confirm self-update aborts on checksum failure and the prior DevSetup installation remains runnable.

## Uninstall isolation
- [ ] Run `devsetup uninstall` and explicitly confirm.
- [ ] Confirm DevSetup files/wrapper are removed.
- [ ] Confirm `java -version` and `javac -version` still work: DevSetup must never uninstall development tools.

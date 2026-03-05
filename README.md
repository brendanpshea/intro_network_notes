# intro_network_notes
Notes for an intro to Networking class.

## Build workflow

From the repository root:

- `powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Mode all`
- `powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Mode pdf`
- `powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Mode html`
- `powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Mode html -Module 1`
- `powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Mode clean`

The build now includes Modules 1 through 9 for both PDF and HTML outputs.

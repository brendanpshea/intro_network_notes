# intro_network_notes

Course materials for **COMP 1080 – Introduction to Networking** at RCTC.

## Structure

| Path | Description |
|------|-------------|
| `network_*.tex` | LaTeX Beamer source files (11 modules) |
| `network_preamble.tex` | Shared LaTeX preamble |
| `PDFs/` | Compiled PDF slide decks |
| `HTML/` | Standalone HTML chapters (LLM-generated from TeX) |
| `HTML/css/lectures.css` | Shared stylesheet for HTML chapters |
| `chapter_guidelines.md` | Detailed guide for converting TeX → HTML |
| `index.html` | Course landing page linking to all modules |
| `scripts/` | Build scripts |

## Building PDFs

From the repository root:

```powershell
# Build all 11 modules
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1

# Build a single module
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Module 5

# Clean build artifacts
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Mode clean
```

## HTML Chapters

HTML chapters are **not** auto-generated from TeX. They are authored (via LLM) as
standalone HTML files that reference `HTML/css/lectures.css` and use Mermaid.js for
diagrams. See [`chapter_guidelines.md`](chapter_guidelines.md) for the conversion process.

## License

CC-BY-NC 4.0

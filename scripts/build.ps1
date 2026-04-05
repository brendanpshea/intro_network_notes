<#
.SYNOPSIS
    Build script for Network+ lecture series - produces beamer slide PDFs.

.DESCRIPTION
    Compiles LaTeX Beamer source files into PDF slide decks using pdflatex.
    Supports all 11 course modules.

    HTML chapters are maintained separately (see chapter_guidelines.md).

.PARAMETER Mode
    Build mode: 'pdf' (default) or 'clean'.

.PARAMETER Module
    Build a single module by number (1-11). Omit to build all modules.

.EXAMPLE
    .\build.ps1                          # Build all PDFs
    .\build.ps1 -Module 5               # PDF for Module 5 only
    .\build.ps1 -Mode clean             # Remove all generated files
#>

param(
    [ValidateSet('pdf','clean')]
    [string]$Mode = 'pdf',

    [ValidateRange(1,11)]
    [int]$Module = 0
)

$ErrorActionPreference = 'Continue'
$scriptRoot = $PSScriptRoot
$repoRoot = Split-Path -Parent $scriptRoot
if (Test-Path (Join-Path $scriptRoot 'network_01_basics.tex')) {
    $repoRoot = $scriptRoot
}
Set-Location $repoRoot

# -- Module registry -----------------------------------------------------------
$modules = @(
    @{ Num = 1;  Base = 'network_01_basics' },
    @{ Num = 2;  Base = 'network_02_phys_inf' },
    @{ Num = 3;  Base = 'network_03_switches_interfaces' },
    @{ Num = 4;  Base = 'network_04_IP' },
    @{ Num = 5;  Base = 'network_05_routing' },
    @{ Num = 6;  Base = 'network_06_nw_services' },
    @{ Num = 7;  Base = 'network_07_nw_app' },
    @{ Num = 8;  Base = 'network_08_operations_monitor' },
    @{ Num = 9;  Base = 'network_09_security_concepts' },
    @{ Num = 10; Base = 'network_10_auth_access_hardening' },
    @{ Num = 11; Base = 'network_11_zones_iot_physical' }
)

if ($Module -ne 0) {
    $modules = $modules | Where-Object { $_.Num -eq $Module }
    if (-not $modules) { Write-Error "Module $Module not found."; exit 1 }
}

# -- Helper: generate .xbb files for icons ------------------------------------
function Ensure-IconXbb {
    $iconDir = Join-Path $repoRoot 'images\icons'
    Get-ChildItem "$iconDir\*.png" | ForEach-Object {
        $xbb = [IO.Path]::ChangeExtension($_.FullName, '.xbb')
        if (-not (Test-Path $xbb)) {
            Write-Host "  Generating $($_.BaseName).xbb ..." -ForegroundColor DarkGray
            Push-Location $iconDir
            & extractbb $_.Name 2>$null
            Pop-Location
        }
    }
}

# -- Build: PDF (beamer) ------------------------------------------------------
function Build-Pdf {
    param([string]$Base)
    $tex = "$Base.tex"
    Write-Host "`n[PDF] Building: $tex" -ForegroundColor Cyan

    if (-not (Test-Path 'PDFs')) { New-Item -ItemType Directory -Path 'PDFs' | Out-Null }

    # Two passes for TOC / cross-references
    foreach ($pass in 1..2) {
        & pdflatex -interaction=nonstopmode -halt-on-error -output-directory=PDFs $tex > $null 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [FAIL] pdflatex pass $pass failed for $tex" -ForegroundColor Red
            return $false
        }
    }

    # Clean up LaTeX auxiliary files from PDFs/ (keep only .pdf)
    $auxExtensions = @('aux','log','nav','out','snm','toc','vrb','dvi','4ct','4tc','idv','lg','tmp','xref')
    foreach ($ext in $auxExtensions) {
        Get-ChildItem "PDFs\*.$ext" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    }

    Write-Host "  [OK] PDFs\$Base.pdf" -ForegroundColor Green
    return $true
}

# -- Clean ---------------------------------------------------------------------
function Invoke-Clean {
    Write-Host "`n[CLEAN] Removing build artifacts..." -ForegroundColor Cyan

    # LaTeX auxiliary files by extension
    $exts = @('*.aux','*.log','*.nav','*.out','*.snm','*.toc','*.vrb',
              '*.dvi','*.4ct','*.4tc','*.idv','*.lg','*.tmp','*.xref',
              '*.fls','*.fdb_latexmk','*.synctex.gz')
    foreach ($ext in $exts) {
        Get-ChildItem $ext -ErrorAction SilentlyContinue | Remove-Item -Force
    }

    # Article tmp files and make4ht intermediate files
    Get-ChildItem '*_article_tmp*' -ErrorAction SilentlyContinue | Remove-Item -Force
    Get-ChildItem '*_make4ht.log' -ErrorAction SilentlyContinue | Remove-Item -Force
    
    # Stale conversion attempts
    Get-ChildItem '*_article_html*','*_converted*' -ErrorAction SilentlyContinue | Remove-Item -Force

    # Root PDF clutter from older builds (keep only PDFs/ directory)
    Get-ChildItem 'network_0*.pdf' -ErrorAction SilentlyContinue | Remove-Item -Force
    
    # Clean PDFs/ directory: keep only final PDFs, remove auxiliary files and stale PDFs
    if (Test-Path 'PDFs') {
        $auxExtensions = @('aux','log','nav','out','snm','toc','vrb','dvi','4ct','4tc','idv','lg','tmp','xref')
        foreach ($ext in $auxExtensions) {
            Get-ChildItem "PDFs\*.$ext" -ErrorAction SilentlyContinue | Remove-Item -Force
        }
        # Remove stale/duplicate PDFs (keep only network_0X_*.pdf files)
        Get-ChildItem "PDFs\*.pdf" -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -match '_article|_converted|_new|_tmp' } |
            Remove-Item -Force
        # Remove misc files
        Get-ChildItem "PDFs\overflow_report*" -ErrorAction SilentlyContinue | Remove-Item -Force
    }

    Write-Host "  [OK] Clean complete" -ForegroundColor Green
}

# -- Main ----------------------------------------------------------------------
$sw = [Diagnostics.Stopwatch]::StartNew()
$results = @()

switch ($Mode) {
    'clean' { Invoke-Clean; break }
    'pdf'   { foreach ($m in $modules) { $results += @{ Module=$m.Num; Type='PDF'; Ok=(Build-Pdf  $m.Base) } } }
}

$sw.Stop()
if ($Mode -ne 'clean') {
    $passed = ($results | Where-Object { $_.Ok }).Count
    $failed = ($results | Where-Object { -not $_.Ok }).Count
    Write-Host "`n--- Summary: $passed passed, $failed failed ($([math]::Round($sw.Elapsed.TotalSeconds, 1))s) ---" -ForegroundColor Cyan
    if ($failed -gt 0) {
        $results | Where-Object { -not $_.Ok } | ForEach-Object {
            Write-Host "  [FAIL] Module $($_.Module) $($_.Type)" -ForegroundColor Red
        }
    }
}

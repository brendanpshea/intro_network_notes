<#
.SYNOPSIS
    Build script for Network+ lecture series - produces beamer PDFs and HTML articles.

.DESCRIPTION
    Two output modes from the same LaTeX source files:
      1. Beamer slides -> PDF  (pdflatex)
      2. HTML articles -> HTML (make4ht via beamerarticle)

    Each module .tex file uses \documentclass{beamer} for slides.
    For HTML, the script generates a temporary *_article_tmp.tex that swaps the
    documentclass to article + beamerarticle, then runs make4ht to produce HTML5.

.PARAMETER Mode
    Build mode: 'all' (default), 'pdf', 'html', or 'clean'.

.PARAMETER Module
    Build a single module by number (1-9). Omit to build all modules.

.EXAMPLE
    .\build.ps1                          # Build everything
    .\build.ps1 -Mode pdf               # PDFs only
    .\build.ps1 -Mode html -Module 5    # HTML for Module 5 only
    .\build.ps1 -Mode clean             # Remove all generated files
#>

param(
    [ValidateSet('all','pdf','html','clean')]
    [string]$Mode = 'all',

    [ValidateRange(1,9)]
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
    @{ Num = 9;  Base = 'network_09_security_concepts' }
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

# -- Helper: extract captions from source .tex and return as hashtable --------
function Get-CaptionsFromSource {
    param([string]$SourceTex)
    
    $captions = @{}
    $lines = Get-Content $SourceTex
    $figIdx = 0
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        # Look for % CAPTION: comments
        if ($lines[$i] -match '^\s*%\s*CAPTION:\s*(.+)$') {
            $caption = $matches[1].Trim()
            $captions[$figIdx] = $caption
            Write-Host "    Found caption $figIdx : $caption" -ForegroundColor DarkGray
            $figIdx++
        }
        # Also count regular tikzpictures to track figure numbers
        elseif ($lines[$i] -match '\\begin\{tikzpicture\}') {
            $figIdx++
        }
    }
    
    return $captions
}

# -- Helper: inject captions into generated HTML figures ----------------------
function Set-HtmlCaptions {
    param([string]$HtmlFile, [hashtable]$Captions)
    
    if ($Captions.Count -eq 0) { return }
    
    $htmlContent = Get-Content $HtmlFile -Raw -Encoding UTF8
    
    # Find and replace figure alt text and captions
    $figIdx = 0
    $htmlContent = [regex]::Replace($htmlContent, 
        "<img alt='[^']*' src='([^']+\.svg)' />" ,
        {
            param($match)
            $svgFile = $match.Groups[1].Value
            if ($Captions.ContainsKey($figIdx)) {
                $caption = $Captions[$figIdx]
                $figIdx++
                return "<img alt='$caption' src='$svgFile' title='$caption' />"
            }
            $figIdx++
            return $match.Value
        }
    )
    
    Set-Content $HtmlFile -Value $htmlContent -Encoding UTF8
}

# -- Helper: create *_article_tmp.tex from the source .tex --------------------
function New-ArticleTmp {
    param([string]$SourceTex)

    $tmpName = [IO.Path]::GetFileNameWithoutExtension($SourceTex) + '_article_tmp.tex'
    $lines   = Get-Content $SourceTex

    $out = @()
    foreach ($line in $lines) {
        # Swap documentclass: comment beamer, uncomment article
        if ($line -match '^\s*\\documentclass\[.*\]\{beamer\}') {
            $out += '%' + $line
            $out += '\documentclass[11pt]{article}            % For article mode'
            $out += '\usepackage{beamerarticle}               % Uncomment with article class'
        }
        # Skip existing commented article/beamerarticle lines to avoid duplication
        elseif ($line -match '^\s*%\s*\\documentclass.*article') { continue }
        elseif ($line -match '^\s*%\s*\\usepackage\{beamerarticle\}')  { continue }
        else {
            $out += $line
        }
    }

    $out | Set-Content $tmpName -Encoding UTF8
    return $tmpName
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

# -- Build: HTML (make4ht + beamerarticle) -------------------------------------
function Build-Html {
    param([string]$Base)
    $tex  = "$Base.tex"
    $htmlDir = "HTML\$Base"
    $htmlRoot = 'HTML'
    Write-Host "`n[HTML] Building: $tex" -ForegroundColor Cyan

    # Ensure icon .xbb files exist
    Ensure-IconXbb

    # Generate article_tmp.tex
    $tmpTex = New-ArticleTmp $tex
    $tmpBase = [IO.Path]::GetFileNameWithoutExtension($tmpTex)
    Write-Host "  Created $tmpTex" -ForegroundColor DarkGray

    # Run make4ht (set LIBGS so dvisvgm can process PostScript specials for PNG icons)
    $env:LIBGS = "$env:LOCALAPPDATA\Programs\MiKTeX\miktex\bin\x64\mgsdll64.dll"
    $make4htLog = "${tmpBase}_make4ht.log"
    & make4ht $tmpTex "html5" > $make4htLog 2>&1

    $htmlFile = "$tmpBase.html"
    if (-not (Test-Path $htmlFile)) {
        Write-Host "  [FAIL] make4ht produced no HTML for $tex" -ForegroundColor Red
        Write-Host "  Check $make4htLog for details" -ForegroundColor Yellow
        return $false
    }

    # Check for TeX errors in the log
    $logFile = "$tmpBase.log"
    $errorCount = 0
    if (Test-Path $logFile) {
        $errorCount = (Select-String -Path $logFile -Pattern '^! ' | Measure-Object).Count
    }
    if ($errorCount -gt 0) {
        Write-Host "  [WARN] $errorCount TeX error(s) in log - HTML may have gaps" -ForegroundColor Yellow
    }

    # Deploy to HTML/<module>/
    if (-not (Test-Path $htmlRoot)) { New-Item -ItemType Directory -Path $htmlRoot -Force | Out-Null }
    if (-not (Test-Path $htmlDir)) { New-Item -ItemType Directory -Path $htmlDir -Force | Out-Null }

    # Ensure shared article stylesheet is available in HTML/
    $sharedCssSource = Join-Path $repoRoot 'scripts\articles.css'
    $sharedCssDest = Join-Path $htmlRoot 'articles.css'
    if (Test-Path $sharedCssSource) {
        Copy-Item $sharedCssSource $sharedCssDest -Force
    }

    # Re-run dvisvgm with --embed-bitmaps so PNG icons inside TikZ are embedded in SVGs
    $idvFile = "$tmpBase.idv"
    $lgFile  = "$tmpBase.lg"
    if ((Test-Path $idvFile) -and (Test-Path $lgFile)) {
        $lgLines = Get-Content $lgFile
        $regenCount = 0
        foreach ($line in $lgLines) {
            if ($line -match '--- needs --- .+\.idv\[(\d+)\] ==> (\S+\.svg)') {
                $page   = $matches[1]
                $svgOut = $matches[2]
                & dvisvgm --embed-bitmaps -n --exact -c 1.4,1.4 -p $page $idvFile -o $svgOut 2>$null
                $regenCount++
            }
        }
        if ($regenCount -gt 0) {
            Write-Host "  Re-generated $regenCount SVG(s) with embedded icons" -ForegroundColor DarkGray
        }
    }

    # Copy HTML as index.html, plus CSS, SVG
    Copy-Item $htmlFile "$htmlDir\index.html" -Force
    Get-ChildItem "$tmpBase*.css" -ErrorAction SilentlyContinue | Copy-Item -Destination $htmlDir -Force
    Get-ChildItem "$tmpBase*.svg" -ErrorAction SilentlyContinue | Copy-Item -Destination $htmlDir -Force

    # Copy images directory to HTML module folder (for icons, diagrams)
    $srcImages = Join-Path $repoRoot 'images'
    $dstImages = Join-Path $htmlDir 'images'
    if (Test-Path $srcImages) {
        if (Test-Path $dstImages) { Remove-Item $dstImages -Recurse -Force }
        Copy-Item $srcImages $dstImages -Recurse -Force
        Write-Host "  Copied images/ to $htmlDir" -ForegroundColor DarkGray
    }

    # Inject shared stylesheet link and ensure UTF-8 charset into generated page
    $indexPath = Join-Path $htmlDir 'index.html'
    if (Test-Path $indexPath) {
        $htmlContent = Get-Content $indexPath -Raw -Encoding UTF8
        
        # Ensure UTF-8 charset is declared
        if ($htmlContent -notmatch 'charset.*utf-?8' -and $htmlContent -notmatch 'meta.*charset') {
            $htmlContent = $htmlContent -replace '(<head[^>]*>)', "`$1`r`n  <meta charset='utf-8'>"
        }
        
        # Inject shared article stylesheet
        if ($htmlContent -notmatch 'articles\.css') {
            $htmlContent = $htmlContent -replace '</head>', "<link href='../articles.css' rel='stylesheet' type='text/css' />`r`n</head>"
        }
        
        Set-Content $indexPath -Value $htmlContent -Encoding UTF8
        
        # Extract captions from source .tex and inject into HTML
        $captions = Get-CaptionsFromSource $tex
        if ($captions.Count -gt 0) {
            Set-HtmlCaptions $indexPath $captions
        }
    }

    # Clean up extraneous build files from root
    Get-ChildItem -File -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -match "^$([regex]::Escape($tmpBase)).*\.(svg|css|4ct|4tc|dvi|idv|lg|tmp|xref|html|log)$" } |
        Remove-Item -Force

    $size = (Get-Item "$htmlDir\index.html").Length
    Write-Host "  [OK] $htmlDir\index.html ($([math]::Round($size/1KB)) KB)" -ForegroundColor Green
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
    
    # Loose SVG/CSS files from make4ht in root (these are copies, real ones are in HTML/<module>/)
    Get-ChildItem '*.svg' -ErrorAction SilentlyContinue | Remove-Item -Force
    Get-ChildItem '*.css' -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -ne 'articles.css' } | 
        Remove-Item -Force
    
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
    'html'  { foreach ($m in $modules) { $results += @{ Module=$m.Num; Type='HTML'; Ok=(Build-Html $m.Base) } } }
    'all'   {
        Write-Host "=== Phase 1: Beamer PDFs ===" -ForegroundColor White
        foreach ($m in $modules) { $results += @{ Module=$m.Num; Type='PDF'; Ok=(Build-Pdf  $m.Base) } }
        Write-Host "`n=== Phase 2: HTML Articles ===" -ForegroundColor White
        foreach ($m in $modules) { $results += @{ Module=$m.Num; Type='HTML'; Ok=(Build-Html $m.Base) } }
    }
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

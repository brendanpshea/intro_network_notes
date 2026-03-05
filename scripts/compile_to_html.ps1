# Compile Network Lecture Notes to HTML via Pandoc
# This script compiles lectures in article mode and converts to HTML
#
# Prerequisites:
#   - Pandoc must be installed: https://pandoc.org/installing.html
#   - LaTeX distribution (MiKTeX or TeX Live) for PDF compilation

Write-Host "Compiling Network Lectures to HTML..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if Pandoc is installed
if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Pandoc is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Please install Pandoc from: https://pandoc.org/installing.html" -ForegroundColor Yellow
    exit 1
}

# Create output directories
if (-not (Test-Path ".\PDFs")) {
    New-Item -ItemType Directory -Path ".\PDFs" | Out-Null
}
if (-not (Test-Path ".\HTML")) {
    New-Item -ItemType Directory -Path ".\HTML" | Out-Null
    Write-Host "Created HTML directory" -ForegroundColor Green
}

# List of lecture files
$lectures = @(
    @{Name="network_01_basics"; Title="Module 1: Network Basics"},
    @{Name="network_02_phys_inf"; Title="Module 2: Physical Infrastructure"},
    @{Name="network_03_switches_interfaces"; Title="Module 3: Switches and Interfaces"},
    @{Name="network_04_IP"; Title="Module 4: IP Addressing"},
    @{Name="network_05_routing"; Title="Module 5: Routing"},
    @{Name="network_06_nw_services"; Title="Module 6: Network Services"},
    @{Name="network_07_nw_app"; Title="Module 7: Network Applications"},
    @{Name="network_08_operations_monitor"; Title="Module 8: Operations and Monitoring"},
    @{Name="network_09_security_concepts"; Title="Module 9: Security Concepts"}
)

foreach ($lecture in $lectures) {
    $name = $lecture.Name
    $title = $lecture.Title
    
    Write-Host "Processing $name..." -ForegroundColor Yellow
    
    # Create a temporary article-mode version of the file
    Write-Host "  Creating article-mode file..." -ForegroundColor Gray
    $content = Get-Content "$name.tex" -Raw
    
    # Switch to article mode
    $content = $content -replace '\\documentclass\[aspectratio=169\]{beamer}', '%\documentclass[aspectratio=169]{beamer}'
    $content = $content -replace '%\\documentclass\[11pt\]{article}', '\documentclass[11pt]{article}'
    $content = $content -replace '%\\usepackage{beamerarticle}', '\usepackage{beamerarticle}'
    
    # Save temporary file
    $tempFile = "temp_$name.tex"
    $content | Set-Content $tempFile -Encoding UTF8
    
    # Convert LaTeX to HTML using Pandoc
    Write-Host "  Converting to HTML..." -ForegroundColor Gray
    pandoc -f latex -t html5 $tempFile -o "HTML\$name.html" `
        --standalone --toc --mathjax `
        --metadata title="$title" `
        --metadata author="Network Course" `
        --css="style.css" `
        --toc-depth=3
    
    if (Test-Path ".\HTML\$name.html") {
        Write-Host "  ✓ HTML created: $name.html" -ForegroundColor Green
    } else {
        Write-Host "  ✗ HTML conversion failed" -ForegroundColor Red
    }
    
    # Clean up temporary file
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Conversion complete!" -ForegroundColor Cyan
Write-Host "HTML files: ./HTML folder" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: You may want to create a style.css file in the HTML folder for better formatting." -ForegroundColor Yellow

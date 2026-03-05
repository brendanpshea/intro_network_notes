# Compile Network Lecture Notes
# This script compiles all lecture files to PDF and places them in the PDFs folder

Write-Host "Compiling Network Lecture Notes..." -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Create PDFs directory if it doesn't exist
if (-not (Test-Path ".\PDFs")) {
    New-Item -ItemType Directory -Path ".\PDFs" | Out-Null
    Write-Host "Created PDFs directory" -ForegroundColor Green
}

# List of lecture files
$lectures = @(
    "network_01_basics",
    "network_02_phys_inf",
    "network_03_switches_interfaces",
    "network_04_IP",
    "network_05_routing",
    "network_06_nw_services",
    "network_07_nw_app",
    "network_08_operations_monitor",
    "network_09_security_concepts"
)

# Compile each lecture
foreach ($lecture in $lectures) {
    Write-Host "Compiling $lecture.tex..." -ForegroundColor Yellow
    
    # Run pdflatex twice for proper references
    pdflatex -interaction=nonstopmode -output-directory=PDFs "$lecture.tex" | Out-Null
    pdflatex -interaction=nonstopmode -output-directory=PDFs "$lecture.tex" | Out-Null
    
    if (Test-Path ".\PDFs\$lecture.pdf") {
        Write-Host "  ✓ Successfully compiled $lecture.pdf" -ForegroundColor Green
        
        # Clean up auxiliary files
        Remove-Item ".\PDFs\$lecture.aux" -ErrorAction SilentlyContinue
        Remove-Item ".\PDFs\$lecture.log" -ErrorAction SilentlyContinue
        Remove-Item ".\PDFs\$lecture.nav" -ErrorAction SilentlyContinue
        Remove-Item ".\PDFs\$lecture.out" -ErrorAction SilentlyContinue
        Remove-Item ".\PDFs\$lecture.snm" -ErrorAction SilentlyContinue
        Remove-Item ".\PDFs\$lecture.toc" -ErrorAction SilentlyContinue
        Remove-Item ".\PDFs\$lecture.vrb" -ErrorAction SilentlyContinue
    } else {
        Write-Host "  ✗ Failed to compile $lecture.pdf" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Compilation complete!" -ForegroundColor Cyan
Write-Host "PDFs are located in the ./PDFs folder" -ForegroundColor Cyan

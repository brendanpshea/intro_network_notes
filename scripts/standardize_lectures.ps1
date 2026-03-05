# PowerShell script to batch-update lectures 4-9 with standardized structure
# This automates the repetitive edits for learning outcomes, key terms removal, and summary updates

Write-Host "Starting lecture standardization for lectures 4-9..." -ForegroundColor Cyan

# Helper function to update a file with multiple replacements
function Update-LectureFile {
    param(
        [string]$FilePath,
        [hashtable[]]$Replacements
    )
    
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    
    foreach ($replacement in $Replacements) {
        $old = $replacement.Old
        $new = $replacement.New
        
        if ($content -match [regex]::Escape($old.Substring(0, [Math]::Min(50, $old.Length)))) {
            $content = $content.Replace($old, $new)
            Write-Host "  ✓ Applied replacement: $($replacement.Name)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Could not find match for: $($replacement.Name)" -ForegroundColor Yellow
        }
    }
    
    Set-Content -Path $FilePath -Value $content -Encoding UTF8 -NoNewline
    Write-Host "Updated: $FilePath" -ForegroundColor Green
}

Write-Host "`nProcessing complete. Please compile PDFs to check for errors." -ForegroundColor Cyan

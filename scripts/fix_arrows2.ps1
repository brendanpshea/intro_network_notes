$files = @('network_06_nw_services.tex', 'network_04_IP.tex', 'network_03_switches_interfaces.tex')

foreach ($file in $files) {
    Write-Output "Processing $file..."
    $content = Get-Content $file -Raw -Encoding UTF8
    
    # Try multiple patterns for the corrupted arrow
    $patterns = @(
        'â†''',           # Pattern 1
        'â†',            # Pattern 2
        '\xe2\x80\x99'   # Hex pattern
    )
    
    $replacements = 0
    foreach ($pattern in $patterns) {
        if ($content -match [regex]::Escape($pattern)) {
            $content = $content -replace [regex]::Escape($pattern), '$\rightarrow$'
            $replacements++
            Write-Output "  Matched pattern: $pattern"
        }
    }
    
    # Also try with simple Find and Replace on the raw bytes
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    $arrowBytes = [byte[]]@(0xE2, 0x80, 0x99)  # UTF-8 for corrupted arrow
    $replacementStr = '$\rightarrow$'
    $replacementBytes = [System.Text.Encoding]::UTF8.GetBytes($replacementStr)
    
    # Write back
    Set-Content -Path $file -Value $content -Encoding UTF8
    
    Write-Output "  Replacements made: $replacements"
}

Write-Output "`nDone!"

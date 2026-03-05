$files = @('network_06_nw_services.tex', 'network_04_IP.tex', 'network_03_switches_interfaces.tex')

foreach ($file in $files) {
    Write-Output "Processing $file..."
    [string]$content = [System.IO.File]::ReadAllText("$file", [System.Text.Encoding]::UTF8)
    
    # Count before
    $before = ($content | Select-String -Pattern 'â' -SimpleMatch | Measure-Object).Count
    
    # Replace the corrupted arrow character: â†' becomes $\rightarrow$
    # â†' is UTF-8 corruption of →
    $fixed = $content -replace 'â†''', '$\rightarrow$'
    
    # Count after
    $after = ($fixed | Select-String -Pattern '\$\\rightarrow\$' | Measure-Object).Count
    
    # Write back
    [System.IO.File]::WriteAllText("$file", $fixed, [System.Text.Encoding]::UTF8)
    
    Write-Output "  Before: $before occurrences, After: $after arrow references"
}

Write-Output "Arrow fix complete!"

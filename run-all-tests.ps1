<#
.SYNOPSIS
Run all k6 test scripts in random order, in parallel.
#>

$testFiles = @(
    "tests\create-tickets-test.js",
    "tests\login-test.js",
    "tests\organizations-search-test.js",
    "tests\search-tickets-test.js",
    "tests\update-tickets-status-test.js"
)

# Shuffle randomly
$shuffledTests = $testFiles | Get-Random -Count $testFiles.Length
Write-Host "Running tests in random parallel order: $($shuffledTests -join ', ')" -ForegroundColor Green

$jobs = @()

foreach ($testFile in $shuffledTests) {
    Write-Host "Starting $testFile..." -ForegroundColor Yellow

    $job = Start-Job -ScriptBlock {
        param($testFile, $scriptRoot)

        Set-Location $scriptRoot

        # Load environment variables from .env file
        $envFile = Join-Path $scriptRoot '.env'
        if (Test-Path $envFile) {
            Get-Content $envFile | ForEach-Object {
                $_ = $_.Trim()
                if ([string]::IsNullOrWhiteSpace($_) -or $_ -like '#*') { return }
                $parts = $_ -split '=', 2
                if ($parts.Length -ne 2) { return }
                $name = $parts[0].Trim()
                $value = $parts[1].Trim()
                if ($name) { Set-Item -Path "Env:$name" -Value $value }
            }
        }

        # Run k6 and capture exit code
        $process = Start-Process -FilePath "k6" -ArgumentList "run `"$testFile`"" -Wait -PassThru
        $exitCode = $process.ExitCode

        # Return results as a hashtable
        return @{
            TestFile = $testFile
            ExitCode = $exitCode
        }

    } -ArgumentList $testFile, $PSScriptRoot

    $jobs += $job
}

Write-Host "All tests started. Waiting for completion..." -ForegroundColor Cyan

# Wait for all jobs and get results
$results = $jobs | Receive-Job -Wait -AutoRemoveJob

$failedTests = @()
foreach ($result in $results) {
    if ($result.ExitCode -ne 0) {
        Write-Host "Test $($result.TestFile) failed with exit code $($result.ExitCode)" -ForegroundColor Red
        $failedTests += $result.TestFile
    } else {
        Write-Host "Test $($result.TestFile) completed successfully" -ForegroundColor Green
    }
}

if ($failedTests.Count -gt 0) {
    Write-Host "Failed tests: $($failedTests -join ', ')" -ForegroundColor Red
    exit 1
} else {
    Write-Host "All tests completed successfully!" -ForegroundColor Green
}

# Generate combined report with all results in one file
Write-Host "Generating combined report: combined-report.html" -ForegroundColor Cyan

$reportFiles = Get-ChildItem -Path . -Filter "*.html" | Where-Object { $_.Name -notmatch "^(index|combined-report)\.html$" } | Sort-Object LastWriteTime -Descending

$combinedHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Combined MSupport Performance Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { text-align: center; color: #333; }
        .test-section { margin: 40px 0; border: 1px solid #ddd; border-radius: 5px; padding: 20px; }
        .test-header { background: #f5f5f5; padding: 10px; margin: -20px -20px 20px -20px; border-radius: 5px 5px 0 0; }
        .test-title { margin: 0; color: #333; }
        .timestamp { color: #666; font-size: 0.9em; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Combined MSupport Performance Test Report</h1>
    <p>Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    <p>This report contains results from all executed tests.</p>
"@

foreach ($file in $reportFiles) {
    $fileName = $file.Name
    $timestamp = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    $content = Get-Content -Path $fileName -Raw
    
    # Extract the table content from the HTML
    $tableStart = $content.IndexOf('<table>')
    if ($tableStart -ge 0) {
        $tableEnd = $content.IndexOf('</table>', $tableStart)
        if ($tableEnd -ge 0) {
            $tableEnd += 8  # Include </table>
            $tableHtml = $content.Substring($tableStart, $tableEnd - $tableStart)
        } else {
            $tableHtml = "<p>Table end not found</p>"
        }
    } else {
        $tableHtml = "<p>No table data found</p>"
    }
    
    $combinedHtml += @"

    <div class="test-section">
        <div class="test-header">
            <h2 class="test-title">$fileName</h2>
            <div class="timestamp">Generated: $timestamp</div>
        </div>
        $tableHtml
    </div>
"@
}

$combinedHtml += @"
    <div style="text-align: center; margin: 20px;">
        <button onclick="downloadReport()" style="padding: 10px 20px; background-color: #4CAF50; color: white; border: none; border-radius: 4px; cursor: pointer;">Save Report</button>
    </div>
    <script>
        function downloadReport() {
            const html = document.documentElement.outerHTML;
            const blob = new Blob([html], {type: 'text/html'});
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'combined-report.html';
            a.click();
            URL.revokeObjectURL(url);
        }
    </script>
</body>
</html>
"@

$combinedHtml | Out-File -FilePath "combined-report.html" -Encoding UTF8

Write-Host "Combined report created: combined-report.html" -ForegroundColor Green

# Delete individual report files
foreach ($file in $reportFiles) {
    Remove-Item $file.FullName -Force
}
Write-Host "Individual report files cleaned up." -ForegroundColor Cyan

# Auto-open the combined report in default browser
Write-Host "Opening combined report in browser..." -ForegroundColor Cyan
Start-Process "combined-report.html"
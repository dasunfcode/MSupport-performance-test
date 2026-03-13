<#
.SYNOPSIS
Run all k6 test scripts in random order, in parallel, and generate a combined HTML report.
#>

# Clean up any leftover HTML reports in the project folder
Get-ChildItem -Path $PSScriptRoot -Filter "*.html" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

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
            Get-Content $envFile | Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object {
                $name, $value = $_ -split '=', 2
                if ($name) { Set-Item -Path "Env:$name" -Value $value.Trim() }
            }
        }

        # Generate a unique HTML report filename in the system temp directory
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $baseName = $($testFile -replace '.js','' -replace 'tests\\','')
        $tempDir = [System.IO.Path]::GetTempPath()
        $reportFile = Join-Path $tempDir "k6-report-$baseName-$timestamp.html"

        # Run k6 and generate HTML report
        $process = Start-Process -FilePath "k6" -ArgumentList "run `"$testFile`" -e K6_REPORT_FILE=`"$reportFile`"" -Wait -PassThru
        $exitCode = $process.ExitCode

        return @{
            TestFile = $testFile
            ExitCode = $exitCode
            ReportFile = $reportFile
        }

    } -ArgumentList $testFile, $PSScriptRoot

    $jobs += $job
}

Write-Host "All tests started. Waiting for completion..." -ForegroundColor Cyan

# Wait for all jobs and get results
$results = $jobs | Receive-Job -Wait -AutoRemoveJob

$failedTests = @()
$reportFiles = @()
foreach ($result in $results) {
    $reportFiles += $result.ReportFile
    if ($result.ExitCode -ne 0) {
        Write-Host "Test $($result.TestFile) failed with exit code $($result.ExitCode)" -ForegroundColor Red
        $failedTests += $result.TestFile
    } else {
        Write-Host "Test $($result.TestFile) completed successfully" -ForegroundColor Green
    }
}

# Generate combined report
Write-Host "Generating combined report: combined-report.html" -ForegroundColor Cyan

$combinedHtml = @"
<!DOCTYPE html>
<html lang='en'>
<head>
<meta charset='UTF-8'>
<title>Combined MSupport Performance Test Report</title>
<style>
body { font-family: Arial, sans-serif; margin: 20px; }
h1 { text-align: center; color: #333; }
.test-section { margin: 40px 0; border: 1px solid #ddd; border-radius: 5px; padding: 20px; }
.test-header { background: #f5f5f5; padding: 10px; margin: -20px -20px 20px -20px; border-radius: 5px 5px 0 0; }
.test-title { margin: 0; color: #333; }
.failed { color: red; }
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
    if (Test-Path $file) {
        $fileName = [System.IO.Path]::GetFileName($file)
        $timestamp = (Get-Item $file).LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        $content = Get-Content -Path $file -Raw

        # Extract table content using regex (more robust)
        $tableHtml = [regex]::Match($content, '<table.*?>.*?</table>', 'Singleline').Value
        if (-not $tableHtml) { $tableHtml = "<p>No table data found</p>" }

        # Highlight failed tests in red
        $titleClass = ""
        if ($failedTests -contains ($fileName -replace '-\d{8}_\d{6}\.html$','.js')) {
            $titleClass = "failed"
        }

        $combinedHtml += @"
<div class='test-section'>
    <div class='test-header'>
        <h2 class='test-title $titleClass'>$fileName</h2>
        <div class='timestamp'>Generated: $timestamp</div>
    </div>
    $tableHtml
</div>
"@

        # Clean up the individual report file so nothing remains in the workspace
        Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
    }
}

$combinedHtml += @"
<div style='text-align: center; margin: 20px;'>
    <button onclick='downloadReport()' style='padding: 10px 20px; background-color: #4CAF50; color: white; border: none; border-radius: 4px; cursor: pointer;'>Save Report</button>
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

# Write combined report to a temp file so the project folder stays clean
$combinedReportPath = Join-Path ([System.IO.Path]::GetTempPath()) "combined-report-$((Get-Date).ToString('yyyyMMdd_HHmmss')).html"
$combinedHtml | Out-File -FilePath $combinedReportPath -Encoding UTF8

Write-Host "Combined report created: $combinedReportPath" -ForegroundColor Green

# Open combined report automatically
Write-Host "Opening combined report in browser..." -ForegroundColor Cyan
Start-Process $combinedReportPath

# Exit with failure if any test failed
if ($failedTests.Count -gt 0) {
    Write-Host "Failed tests: $($failedTests -join ', ')" -ForegroundColor Red
    exit 1
} else {
    Write-Host "All tests completed successfully!" -ForegroundColor Green
}
$testFiles = @(
    "tests\create-tickets-test.js",
    "tests\organizations-search-test.js",
    "tests\search-tickets-test.js",
    "tests\update-tickets-status-test.js"
)

$shuffledTests = $testFiles | Get-Random -Count $testFiles.Length
Write-Host "Running tests in random parallel order: $($shuffledTests -join ', ')" -ForegroundColor Green

$jobs = @()

foreach ($testFile in $shuffledTests) {

    Write-Host "Starting $testFile..." -ForegroundColor Yellow

    $job = Start-Job -ScriptBlock {

        param($testFile, $scriptRoot)

        Set-Location $scriptRoot

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

        $process = Start-Process -FilePath "k6" -ArgumentList "run `"$testFile`"" -Wait -PassThru

        return @{
            TestFile = $testFile
            ExitCode = $process.ExitCode
        }

    } -ArgumentList $testFile, $PSScriptRoot

    $jobs += $job
}

Write-Host "All tests started. Waiting for completion..." -ForegroundColor Cyan

$results = $jobs | Receive-Job -Wait -AutoRemoveJob

$failedTests = @()

foreach ($result in $results) {

    if ($result.ExitCode -ne 0) {
        Write-Host "Test $($result.TestFile) failed" -ForegroundColor Red
        $failedTests += $result.TestFile
    }
    else {
        Write-Host "Test $($result.TestFile) completed successfully" -ForegroundColor Green
    }
}

if ($failedTests.Count -gt 0) {
    Write-Host "Failed tests: $($failedTests -join ', ')" -ForegroundColor Red
    exit 1
}

Write-Host "All tests completed successfully" -ForegroundColor Green
Write-Host "Generating combined report..." -ForegroundColor Cyan

$reportFiles = Get-ChildItem -Path . -Filter "*.html" |
Where-Object { $_.Name -notmatch "^(index|combined-report)\.html$" } |
Sort-Object LastWriteTime -Descending

$combinedHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>MSupport Performance Test Report</title>

<style>

body{
font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
background:#f6f8fb;
margin:0;
padding:40px;
color:#2c3e50;
}

.container{
max-width:1200px;
margin:auto;
}

h1{
font-size:28px;
font-weight:600;
margin-bottom:8px;
}

.subtitle{
color:#6b7280;
margin-bottom:40px;
}

.test-card{
background:#ffffff;
border:1px solid #e5e7eb;
border-radius:10px;
padding:24px;
margin-bottom:30px;
box-shadow:0 2px 6px rgba(0,0,0,0.05);
}

.test-header{
display:flex;
justify-content:space-between;
align-items:center;
margin-bottom:16px;
}

.test-title{
font-size:18px;
font-weight:600;
margin:0;
}

.timestamp{
font-size:13px;
color:#6b7280;
}

table{
width:100%;
border-collapse:collapse;
font-size:14px;
}

th{
text-align:left;
padding:10px;
background:#f3f4f6;
border-bottom:1px solid #e5e7eb;
font-weight:600;
}

td{
padding:10px;
border-bottom:1px solid #f1f1f1;
}

tr:hover{
background:#fafafa;
}

.footer{
text-align:center;
margin-top:40px;
}

button{
background:#2563eb;
color:white;
border:none;
padding:10px 20px;
border-radius:6px;
font-size:14px;
cursor:pointer;
}

button:hover{
background:#1e4fd8;
}

</style>
</head>

<body>

<div class="container">

<h1>MSupport Load Test Report</h1>
<div class="subtitle">Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</div>

"@

foreach ($file in $reportFiles) {

    $content = Get-Content -Path $file.FullName -Raw

    $tableStart = $content.IndexOf('<table>')
    $tableEnd = $content.IndexOf('</table>', $tableStart)

    if ($tableStart -ge 0 -and $tableEnd -ge 0) {
        $tableEnd += 8
        $tableHtml = $content.Substring($tableStart, $tableEnd - $tableStart)
    }
    else {
        $tableHtml = "<p>No table data found</p>"
    }

$combinedHtml += @"

<div class="test-card">

<div class="test-header">
<div class="test-title">$($file.Name)</div>
<div class="timestamp">$($file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"))</div>
</div>

$tableHtml

</div>

"@
}

$combinedHtml += @"

<div class="footer">
<button onclick="downloadReport()">Download Report</button>
</div>

</div>

<script>
function downloadReport(){
const html=document.documentElement.outerHTML;
const blob=new Blob([html],{type:'text/html'});
const url=URL.createObjectURL(blob);
const a=document.createElement('a');
a.href=url;
a.download='combined-report.html';
a.click();
URL.revokeObjectURL(url);
}
</script>

</body>
</html>
"@

$combinedHtml | Out-File -FilePath "combined-report.html" -Encoding UTF8

Write-Host "Combined report created: combined-report.html" -ForegroundColor Green

foreach ($file in $reportFiles) {
Remove-Item $file.FullName -Force
}

Write-Host "Individual report files cleaned up" -ForegroundColor Cyan

Start-Process "combined-report.html"
<#
Helper script to run k6 using environment variables defined in .env.
Usage:
  .\run-k6.ps1 run tests/create-tickets-test.js
#>

$envFile = Join-Path $PSScriptRoot '.env'
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

# Set flag for single test report
$env:SINGLE_TEST = "1"

k6 @Args

# Open the report if it was generated
if (Test-Path "report.html") {
  Start-Process "report.html"
}

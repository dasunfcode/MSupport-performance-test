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

        # Set environment variables safely
        $envVars = @{
            BASE_URL = "https://qa.msupport.mone.am/api/v1"
            OTHER_ENV = "someValue"
        }

        foreach ($name in $envVars.Keys) {
            Set-Item -Path "Env:$name" -Value $envVars[$name]
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
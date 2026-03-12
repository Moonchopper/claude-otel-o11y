[CmdletBinding()]
param(
    [switch]$Env,
    [switch]$Check,
    [switch]$Clean,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

$vars = @{
    "CLAUDE_CODE_ENABLE_TELEMETRY" = "1"
    "OTEL_METRICS_EXPORTER"        = "otlp"
    "OTEL_LOGS_EXPORTER"           = "otlp"
    "OTEL_EXPORTER_OTLP_ENDPOINT"  = "http://localhost:4317"
    "OTEL_EXPORTER_OTLP_PROTOCOL"  = "grpc"
}

function Test-Environment {
    Write-Host "Checking Claude Code OTel environment variables..."
    Write-Host ""

    $allGood = $true
    foreach ($entry in $vars.GetEnumerator()) {
        $actual = [System.Environment]::GetEnvironmentVariable($entry.Key, "User")
        $display = "$($entry.Key)=$($entry.Value)"
        if ($actual -eq $entry.Value) {
            Write-Host ("  {0,-45} {1}" -f $display, [char]0x2713) -ForegroundColor Green
        } elseif ($actual) {
            Write-Host ("  {0,-45} {1}" -f "$($entry.Key)=$actual", "expected: $($entry.Value)") -ForegroundColor Red
            $allGood = $false
        } else {
            Write-Host ("  {0,-45} {1}" -f $entry.Key, "(not set)") -ForegroundColor Red
            $allGood = $false
        }
    }

    Write-Host ""
    $containerRunning = $false
    try {
        $status = docker compose ps --status running 2>$null
        if ($status -match "otel-collector") { $containerRunning = $true }
    } catch {}

    if ($containerRunning) {
        Write-Host "  OTel Collector container:                running" -ForegroundColor Green
    } else {
        Write-Host "  OTel Collector container:                not running" -ForegroundColor Red
        $allGood = $false
    }

    Write-Host ""
    if ($allGood) {
        Write-Host "Everything looks good! Start a Claude Code session to generate telemetry." -ForegroundColor Green
    } else {
        Write-Host "Some checks failed. Run '.\setup.ps1' to configure everything." -ForegroundColor Yellow
    }
}

function Set-Environment {
    Write-Host "Setting user environment variables..."
    Write-Host ""

    foreach ($entry in $vars.GetEnumerator()) {
        [System.Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, "User")
        # Also set in current session
        Set-Item -Path "Env:\$($entry.Key)" -Value $entry.Value
        Write-Host "  Set $($entry.Key) = $($entry.Value)"
    }

    Write-Host ""
    Write-Host "Variables set at user level (persistent across reboots)."
    Write-Host "Restart VS Code or open a new terminal to pick up the changes."
}

function Remove-Environment {
    Write-Host "Removing user environment variables..."
    Write-Host ""

    foreach ($entry in $vars.GetEnumerator()) {
        [System.Environment]::SetEnvironmentVariable($entry.Key, $null, "User")
        Remove-Item -Path "Env:\$($entry.Key)" -ErrorAction SilentlyContinue
        Write-Host "  Removed $($entry.Key)"
    }

    Write-Host ""
    Write-Host "Tearing down Docker stack..."
    docker compose down -v 2>$null
    Write-Host "Done."
}

function Start-Stack {
    Write-Host "Starting Docker stack..."
    docker compose up -d
    Write-Host ""
    Write-Host "Services:"
    Write-Host "  OTel Collector:  localhost:4317 (gRPC), localhost:4318 (HTTP)"
    Write-Host "  Prometheus:      http://localhost:9090"
    Write-Host "  Grafana:         http://localhost:3000 (admin/admin)"
}

function Show-Usage {
    Write-Host "Usage: .\setup.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  (none)     Set environment variables and start Docker stack"
    Write-Host "  -Env       Only set environment variables"
    Write-Host "  -Check     Only verify current configuration"
    Write-Host "  -Clean     Remove variables and tear down stack"
    Write-Host "  -Help      Show this help"
}

if ($Help) {
    Show-Usage
} elseif ($Check) {
    Test-Environment
} elseif ($Env) {
    Set-Environment
} elseif ($Clean) {
    Remove-Environment
} else {
    Set-Environment
    Write-Host ""
    Start-Stack
    Write-Host ""
    Write-Host "Restart VS Code or open a new terminal, then start a Claude Code session." -ForegroundColor Cyan
    Write-Host "Run '.\setup.ps1 -Check' to verify everything is configured." -ForegroundColor Cyan
}

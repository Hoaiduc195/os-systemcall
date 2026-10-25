# Auto-accept watcher for Herdr agents (e.g. Codex / boss)
param(
    [string]$Target = "boss",
    [int]$IntervalMs = 800
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=========================================="
Write-Host "Herdr Auto-Accept Watcher active for: $Target"
Write-Host "Interval: ${IntervalMs}ms"
Write-Host "=========================================="

while ($true) {
    try {
        $infoJson = & herdr agent get $Target 2>$null
        if ($infoJson) {
            $info = $infoJson | ConvertFrom-Json
            $status = $info.result.agent.agent_status

            if ($status -eq "blocked") {
                $output = & herdr agent read $Target --source visible 2>$null
                if ($output -match "Would you like to run the following command|Press enter to confirm|Yes, proceed") {
                    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    Write-Host "[$timestamp] Detected blocked prompt on $Target. Sending 'enter' to auto-accept..."
                    & herdr agent send-keys $Target enter 2>$null | Out-Null
                    Start-Sleep -Milliseconds 600
                }
            }
        } else {
            # If target name not found, fallback to checking codex in current workspace or wC:p1
            $agentsJson = & herdr agent list 2>$null
            if ($agentsJson) {
                $agents = ($agentsJson | ConvertFrom-Json).result.agents
                $codexAgent = $agents | Where-Object { $_.agent -eq "codex" -and $_.pane_id -eq "wC:p1" }
                if ($codexAgent -and $codexAgent.agent_status -eq "blocked") {
                    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    Write-Host "[$timestamp] Detected blocked prompt on $($codexAgent.pane_id). Sending 'enter' to auto-accept..."
                    & herdr agent send-keys $codexAgent.pane_id enter 2>$null | Out-Null
                    Start-Sleep -Milliseconds 600
                }
            }
        }
    } catch {
        # ignore transient exceptions
    }

    Start-Sleep -Milliseconds $IntervalMs
}

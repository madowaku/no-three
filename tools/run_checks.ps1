param(
    [Parameter(Mandatory = $true)][string]$Godot,
    [string]$Python = 'python',
    [switch]$Visual,
    [string]$GodotSkillRoot
)
$ErrorActionPreference = 'Stop'
$taskProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $taskProjectRoot
New-Item -ItemType Directory -Path evidence -Force | Out-Null

function Invoke-GodotCheck([string]$Label, [string[]]$Arguments) {
    $taskLog = @(& $Godot @Arguments 2>&1)
    $taskExit = $LASTEXITCODE
    $taskLog | Set-Content -LiteralPath "evidence/$Label.log" -Encoding utf8
    $taskLog | Where-Object { $_ -match '^(PROJECT |TESTS |TOUCH |Stage .+ runtime |\[SCENARIO\] ui_report)' } | Write-Output
    if ($taskExit -ne 0 -or ($taskLog -match 'SCRIPT ERROR:|ERROR:|WARNING:|CrashHandlerException')) {
        $taskLog | Write-Output
        throw "$Label failed; see evidence/$Label.log"
    }
}

& $Python tools/validate_stages.py
if ($LASTEXITCODE -ne 0) { throw 'Stage validation failed' }
& $Python -m unittest discover -s tests -p 'test_*.py'
if ($LASTEXITCODE -ne 0) { throw 'Python tests failed' }
Invoke-GodotCheck 'import' @('--headless', '--path', $taskProjectRoot, '--import')
Invoke-GodotCheck 'static' @('--headless', '--debug', '--ignore-error-breaks', '--path', $taskProjectRoot, '--script', 'res://tests/check_project.gd')
Invoke-GodotCheck 'boot' @('--headless', '--debug', '--ignore-error-breaks', '--path', $taskProjectRoot, '--quit-after', '120')
Invoke-GodotCheck 'runtime_tests' @('--headless', '--debug', '--ignore-error-breaks', '--path', $taskProjectRoot, '--script', 'res://tests/run_tests.gd')
if ($Visual) {
    Invoke-GodotCheck 'touch' @('--debug', '--ignore-error-breaks', '--path', $taskProjectRoot, '--script', 'res://tests/test_touch.gd')
    if (-not $GodotSkillRoot) { throw 'Visual scenarios require -GodotSkillRoot' }
    $taskRunner = Join-Path $GodotSkillRoot 'scripts/debug/scenario_runner.gd'
    foreach ($taskScenario in @('title_720', 'title_360', 'puzzle_720', 'puzzle_360', 'campaign_ui_720', 'campaign_ui_360', 'board_sizes_720', 'board_sizes_360')) {
        # The external scenario runner has enum warnings in Godot 4.7; project
        # scripts are checked with the debugger separately above.
        Invoke-GodotCheck $taskScenario @('--path', $taskProjectRoot, '--script', $taskRunner, "tests/scenarios/$taskScenario.json")
    }
}
Write-Output 'ALL CHECKS PASS'

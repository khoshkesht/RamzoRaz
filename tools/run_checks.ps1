param(
    [string]$Godot = 'E:\Projects\Godot_v4.7.2\Godot_v4.7.2-stable_win64_console.exe',
    [switch]$VisualTests
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path $projectRoot '.tools'
New-Item -ItemType Directory -Force $logDir | Out-Null
& (Join-Path $PSScriptRoot 'prepare_godot_imports.ps1')
Push-Location $projectRoot
try {
    & $Godot --headless --path $projectRoot --editor --quit --log-file ((Join-Path $logDir 'import.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_foundation.gd --log-file ((Join-Path $logDir 'foundation.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Foundation checks failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_production_levels.gd --log-file ((Join-Path $logDir 'production-levels.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Production stage checks failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_chapter_two.gd --log-file ((Join-Path $logDir 'chapter-two.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Stages 11 to 20 checks failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_chapter_three.gd --log-file ((Join-Path $logDir 'chapter-three.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Stages 21 to 30 checks failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_chapter_four.gd --log-file ((Join-Path $logDir 'chapter-four.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Stages 31 to 50 checks failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_chapter_five.gd --log-file ((Join-Path $logDir 'chapter-five.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Stages 51 to 70 checks failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_final_chapters.gd --log-file ((Join-Path $logDir 'final-chapters.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Stages 71 to 101 checks failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_interactions.gd --log-file ((Join-Path $logDir 'interactions.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Interaction checks failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_rules_actions.gd --log-file ((Join-Path $logDir 'rules-actions.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Rule and action checks failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_lifecycle.gd --log-file ((Join-Path $logDir 'lifecycle.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Lifecycle checks failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_progress_hints.gd --log-file ((Join-Path $logDir 'progress-hints.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Progress and hint checks failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_application.gd --log-file ((Join-Path $logDir 'application.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Application checks failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_settings.gd --log-file ((Join-Path $logDir 'settings.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Settings checks failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_toolbar.gd --log-file ((Join-Path $logDir 'toolbar.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Toolbar checks failed' }
    & (Join-Path $projectRoot 'tests/test_build_number.ps1')
    # Native screen transforms are unavailable in headless mode; this regression
    # check uses a real desktop window and a simulated Android safe-area provider.
    if ($VisualTests) {
        & $Godot --path $projectRoot --script res://tests/test_safe_margin.gd --log-file ((Join-Path $logDir 'safe-margin.log').Replace('\','/'))
        if ($LASTEXITCODE -ne 0) { throw 'Safe area regression checks failed' }
    }
    & $Godot --headless --path $projectRoot --script res://tests/test_ui_layout.gd --log-file ((Join-Path $logDir 'ui-layout.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'UI layout checks failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_production_layout.gd --log-file ((Join-Path $logDir 'production-layout.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Production stage layout checks failed' }
    & $Godot --headless --path $projectRoot --script res://tests/test_home_layout.gd --log-file ((Join-Path $logDir 'home-layout.log').Replace('\','/'))
    if ($LASTEXITCODE -ne 0) { throw 'Home layout checks failed' }
} finally { Pop-Location }

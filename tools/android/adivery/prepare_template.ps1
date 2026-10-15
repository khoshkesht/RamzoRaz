param([string]$Templates = (Join-Path $env:APPDATA 'Godot/export_templates/4.7.2.stable'))
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$androidRoot = Join-Path $projectRoot 'android'
$destination = Join-Path $androidRoot 'build'
$versionFile = Join-Path $androidRoot '.build_version'
if (Test-Path -LiteralPath $destination) {
    if ((Test-Path -LiteralPath $versionFile) -and (Get-Content -LiteralPath $versionFile -Raw).Trim() -eq '4.7.2.stable') {
        Write-Output 'Godot 4.7.2 Android build template is already installed.'
        exit 0
    }
    throw 'An existing Android build directory has a different or unknown version. It was not overwritten.'
}
New-Item -ItemType Directory -Force -Path $androidRoot | Out-Null
[IO.File]::WriteAllBytes((Join-Path $androidRoot '.gdignore'), [byte[]]@())
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $Templates 'android_source.zip'), $destination)
[IO.File]::WriteAllBytes((Join-Path $destination '.gdignore'), [byte[]]@())
[IO.File]::WriteAllText($versionFile, "4.7.2.stable`n", [Text.UTF8Encoding]::new($false))
Write-Output 'Installed the local Godot 4.7.2 Android build template. No Gradle build or APK was run.'

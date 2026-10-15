param(
    [string]$Templates = (Join-Path $env:APPDATA 'Godot/export_templates/4.7.2.stable'),
    [string]$AndroidSdk = (Join-Path $env:LOCALAPPDATA 'Android/Sdk'),
    [string]$JavaBin = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot\bin'
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$bridgeRoot = Join-Path $projectRoot '.tools/adivery'
$buildRoot = Join-Path $bridgeRoot ('build-' + [Guid]::NewGuid().ToString('N'))
$classesRoot = Join-Path $buildRoot 'classes'
$aarRoot = Join-Path $buildRoot 'aar'
$outputRoot = Join-Path $projectRoot 'addons/adivery/bin'
New-Item -ItemType Directory -Force -Path $classesRoot, $aarRoot, $outputRoot | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Expand-ArchiveEntry([string]$Archive, [string]$Entry, [string]$Destination) {
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        $item = $zip.GetEntry($Entry)
        if ($null -eq $item) { throw "Missing $Entry in $Archive" }
        [IO.Compression.ZipFileExtensions]::ExtractToFile($item, $Destination, $true)
    } finally { $zip.Dispose() }
}

# Read only the pinned project's export template. Never fetch or run another Godot version.
$sourceTemplate = Join-Path $Templates 'android_source.zip'
$godotAar = Join-Path $bridgeRoot 'godot.aar'
$godotJar = Join-Path $bridgeRoot 'godot.jar'
Expand-ArchiveEntry $sourceTemplate 'libs/debug/godot-lib.template_debug.aar' $godotAar
Expand-ArchiveEntry $godotAar 'classes.jar' $godotJar
$sdkAar = Join-Path $bridgeRoot 'sdk-4.9.0.aar'
if (-not (Test-Path -LiteralPath $sdkAar)) {
    Invoke-WebRequest -Uri 'https://repo.maven.apache.org/maven2/com/adivery/sdk/4.9.0/sdk-4.9.0.aar' -OutFile $sdkAar -UseBasicParsing
}
if ((Get-FileHash -LiteralPath $sdkAar -Algorithm SHA256).Hash -ne '8A46A7351B60C105E35ED73038B3999752E2563F36783D7E046EBE25D44F71E2') {
    throw 'Adivery SDK archive differs from the pinned 4.9.0 artifact.'
}
$sdkJar = Join-Path $bridgeRoot 'sdk.jar'
Expand-ArchiveEntry $sdkAar 'classes.jar' $sdkJar
$androidJar = Join-Path $bridgeRoot 'android-36.jar'
Copy-Item -LiteralPath (Join-Path $AndroidSdk 'platforms/android-36/android.jar') -Destination $androidJar -Force
$classPath = @($androidJar, $godotJar, $sdkJar) -join [IO.Path]::PathSeparator

# Compile and package only this Java library. No game, test, APK, or device command is run.
& (Join-Path $JavaBin 'javac.exe') -encoding UTF-8 --release 17 -classpath $classPath -d $classesRoot (Join-Path $PSScriptRoot 'AdiveryPlugin.java')
if ($LASTEXITCODE -ne 0) { throw 'Adivery bridge compilation failed.' }
& (Join-Path $JavaBin 'jar.exe') --create --file (Join-Path $aarRoot 'classes.jar') -C $classesRoot .
if ($LASTEXITCODE -ne 0) { throw 'Adivery bridge JAR packaging failed.' }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'AndroidManifest.xml') -Destination $aarRoot
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'consumer-rules.pro') -Destination (Join-Path $aarRoot 'proguard.txt')
$stagedAar = Join-Path $buildRoot 'ramzoraz-adivery.aar'
[IO.Compression.ZipFile]::CreateFromDirectory($aarRoot, $stagedAar)
Copy-Item -LiteralPath $stagedAar -Destination (Join-Path $outputRoot 'ramzoraz-adivery.aar') -Force
Write-Output 'Packaged addons/adivery/bin/ramzoraz-adivery.aar (Godot 4.7.2 / Adivery 4.9.0). No APK or tests were run.'

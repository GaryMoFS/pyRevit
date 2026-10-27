param(
    [Parameter(Mandatory = $true)][string]$SeedBin,
    [string]$Revit2019Path = (Join-Path $env:ProgramFiles 'Autodesk\Revit 2019'),
    [string]$Dotnet = 'dotnet'
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$bin = Join-Path $root 'bin'
if (Test-Path -LiteralPath $bin) { throw "Use a clean checkout: bin already exists at $bin" }
if (-not (Test-Path -LiteralPath (Join-Path $SeedBin 'pyrevit.exe'))) { throw 'SeedBin must contain the bin folder from the matching pyRevit 7.0.0.26278 release.' }
if (-not (Test-Path -LiteralPath (Join-Path $Revit2019Path 'RevitAPI.dll'))) { throw "RevitAPI.dll not found under $Revit2019Path" }
Copy-Item -LiteralPath $SeedBin -Destination $bin -Recurse
function Invoke-Build([string[]]$ArgsList) {
    & $Dotnet @ArgsList
    if ($LASTEXITCODE -ne 0) { throw "dotnet failed with exit code $LASTEXITCODE" }
}
Push-Location $root
try {
    $revitPathProperty = "-p:Revit2019Path=$Revit2019Path"
    Invoke-Build -ArgsList @('build', 'dev/pyRevitLabs/pyRevitLabs.TargetApps.Revit/pyRevitLabs.TargetApps.Revit.csproj', '-c', 'Release', '-f', 'net48')
    foreach ($engine in @('IPY2712PR','IPY342')) {
        $loader = if ($engine -eq 'IPY342') { 'dev/pyRevitLoader/pyRevitLoader.342/pyRevitLoader.342.csproj' } else { 'dev/pyRevitLoader/pyRevitLoader.2712PR/pyRevitLoader.2712PR.csproj' }
        Invoke-Build -ArgsList @('build', $loader, '-c', "Release $engine", '-f', 'net48', '-p:RevitVersion=2019', $revitPathProperty)
        Invoke-Build -ArgsList @('build', 'dev/pyRevitLabs.PyRevit.Runtime/2019/pyRevitLabs.PyRevit.Runtime.2019.csproj', '-c', "Release $engine", $revitPathProperty)
        $engineDir = Join-Path $bin "netfx/engines/$engine"
        foreach ($revitAssembly in @('RevitAPI.dll', 'RevitAPIUI.dll', 'RevitDBAPI.dll', 'APIInterop.dll', 'UtilityAPI.dll')) {
            if (Test-Path -LiteralPath (Join-Path $engineDir $revitAssembly)) {
                throw "Unexpected Revit application assembly in $engineDir`: $revitAssembly. Build from a clean official release bin and keep Revit references non-copy-local."
            }
        }
    }
    $publish = Join-Path $root 'build/revit2019-cli-publish'
    Invoke-Build -ArgsList @('publish', 'dev/pyRevitLabs/pyRevitCLI/pyRevitCLI.csproj', '-c', 'Release', '-r', 'win-x64', '--self-contained', 'true', '-o', $publish)
    Copy-Item (Join-Path $publish '*') $bin -Recurse -Force
    foreach ($folder in @('bin','bin/netfx','bin/netcore')) { Copy-Item 'release/pyrevit-hosts.json' (Join-Path $folder 'pyrevit-hosts.json') -Force }
    Write-Host 'Build complete. Compile release/pyrevit-revit2019-experimental.iss with Inno Setup 7.'
}
finally { Pop-Location }


[CmdletBinding()]
param(
    [string]$OutputDir = (Join-Path $PSScriptRoot 'Launchers'),
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

function Show-Help {
    @'
Usage: create_launchers.bat [-OutputDir <path>]

Generate Windows launcher .bat files for DOS games and console ROMs.

Examples:
  create_launchers.bat
  create_launchers.bat -OutputDir D:\Games\Launchers
'@ | Write-Host
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$From,
        [Parameter(Mandatory = $true)][string]$To
    )

    $comparison = if ($IsWindows) { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
    $fromPath = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $From).Path)
    $toPath = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $To).Path)
    $fromParts = ($fromPath -split '[\\/]') | Where-Object { $_ -ne '' }
    $toParts = ($toPath -split '[\\/]') | Where-Object { $_ -ne '' }
    $commonIndex = 0

    while ($commonIndex -lt $fromParts.Count -and $commonIndex -lt $toParts.Count -and $fromParts[$commonIndex].Equals($toParts[$commonIndex], $comparison)) {
        $commonIndex += 1
    }

    $relativeParts = New-Object System.Collections.Generic.List[string]
    for ($index = $commonIndex; $index -lt $fromParts.Count; $index += 1) {
        $relativeParts.Add('..')
    }
    for ($index = $commonIndex; $index -lt $toParts.Count; $index += 1) {
        $relativeParts.Add($toParts[$index])
    }

    if ($relativeParts.Count -eq 0) {
        return '.'
    }

    return ($relativeParts -join [IO.Path]::DirectorySeparatorChar)
}

function Convert-ToBatchLiteral {
    param([Parameter(Mandatory = $true)][string]$Value)

    return $Value.Replace('"', '""')
}

function Write-WindowsLauncher {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][ValidateSet('dos', 'rom')][string]$Mode,
        [Parameter(Mandatory = $true)][string]$GameName,
        [Parameter(Mandatory = $true)][string]$TargetDir,
        [Parameter(Mandatory = $true)][string]$FileName,
        [string]$Platform
    )

    $gameNameLiteral = Convert-ToBatchLiteral $GameName
    $targetDirLiteral = Convert-ToBatchLiteral $TargetDir
    $fileLiteral = Convert-ToBatchLiteral $FileName
    $platformClause = ''

    if ($Platform) {
        $platformLiteral = Convert-ToBatchLiteral $Platform
        $platformClause = " -Platform `"$platformLiteral`""
    }

    $content = @"
@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%$script:ProjectRelativePath\\.") do set "PROJECT_DIR=%%~fI"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_DIR%\Configuration\launch_windows.ps1" -Mode $Mode -GameName "$gameNameLiteral" -TargetDir "$targetDirLiteral" -FileName "$fileLiteral"$platformClause -ProjectDir "%PROJECT_DIR%"
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
    echo Launcher failed with exit code %EXIT_CODE%.
    pause
)
exit /b %EXIT_CODE%
"@

    Set-Content -LiteralPath $Path -Value $content -Encoding ASCII
}

function Test-Ps1BinReferencedByCue {
    param(
        [Parameter(Mandatory = $true)][string]$RomDirectory,
        [Parameter(Mandatory = $true)][string]$BinFileName
    )

    foreach ($cueFile in Get-ChildItem -LiteralPath $RomDirectory -Filter '*.cue' -File -ErrorAction SilentlyContinue) {
        if (Select-String -LiteralPath $cueFile.FullName -SimpleMatch -Pattern $BinFileName -Quiet) {
            return $true
        }
    }

    return $false
}

if ($Help) {
    Show-Help
    exit 0
}

$RepoRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$ProgramsDir = Join-Path $RepoRoot 'Programs'
$RomsDir = Join-Path $RepoRoot 'ROMs'
$LogsDir = Join-Path $RepoRoot 'Logs'

New-Item -ItemType Directory -Force -Path $OutputDir, $LogsDir | Out-Null
$OutputDir = (Resolve-Path -LiteralPath $OutputDir).Path
$script:ProjectRelativePath = Get-RelativePath -From $OutputDir -To $RepoRoot

Write-Host "=== DOS_Launcher Windows generator ==="
Write-Host "Base directory: $RepoRoot"
Write-Host "Output directory: $OutputDir"
Write-Host "Project path from launchers: $script:ProjectRelativePath"
Write-Host

foreach ($programDir in Get-ChildItem -LiteralPath $ProgramsDir -Directory | Sort-Object Name) {
    $exe = Get-ChildItem -LiteralPath $programDir.FullName -File |
        Where-Object { $_.Extension -match '^\.(exe|com|bat)$' } |
        Sort-Object Length -Descending |
        Select-Object -First 1

    if (-not $exe) {
        Write-Host "Skipping $($programDir.Name): no DOS executable found"
        continue
    }

    $launcherPath = Join-Path $OutputDir ("start_DOS_{0}.bat" -f $programDir.Name)
    Write-WindowsLauncher -Path $launcherPath -Mode dos -GameName $programDir.Name -TargetDir (Join-Path 'Programs' $programDir.Name) -FileName $exe.Name
    Write-Host "Created $launcherPath"
}

$platformPatterns = @{
    'GB'  = @('*.gb', '*.gbc')
    'GBA' = @('*.gba')
    'PS1' = @('*.cue', '*.bin', '*.iso', '*.img')
    'PS2' = @('*.iso', '*.bin', '*.cue')
    'PSP' = @('*.iso', '*.cso')
    'N64' = @('*.n64', '*.z64', '*.v64')
}

foreach ($romDir in Get-ChildItem -LiteralPath $RomsDir -Directory | Sort-Object Name) {
    if (-not $platformPatterns.ContainsKey($romDir.Name)) {
        Write-Host "Skipping unsupported platform directory $($romDir.Name)"
        continue
    }

    foreach ($pattern in $platformPatterns[$romDir.Name]) {
        foreach ($romFile in Get-ChildItem -LiteralPath $romDir.FullName -Filter $pattern -File -ErrorAction SilentlyContinue | Sort-Object Name) {
            if ($romDir.Name -eq 'PS1' -and $romFile.Extension -ieq '.bin' -and (Test-Ps1BinReferencedByCue -RomDirectory $romDir.FullName -BinFileName $romFile.Name)) {
                continue
            }

            $launcherPath = Join-Path $OutputDir ("start_{0}_{1}.bat" -f $romDir.Name, $romFile.BaseName)
            Write-WindowsLauncher -Path $launcherPath -Mode rom -Platform $romDir.Name -GameName $romFile.BaseName -TargetDir (Join-Path 'ROMs' $romDir.Name) -FileName $romFile.Name
            Write-Host "Created $launcherPath"
        }
    }
}

Write-Host
Write-Host 'Launcher generation complete.'
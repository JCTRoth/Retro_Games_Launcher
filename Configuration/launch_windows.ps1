[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet('dos', 'rom')][string]$Mode,
    [Parameter(Mandatory = $true)][string]$GameName,
    [Parameter(Mandatory = $true)][string]$TargetDir,
    [Parameter(Mandatory = $true)][string]$FileName,
    [string]$Platform,
    [string]$ProjectDir = (Join-Path $PSScriptRoot '..')
)

$ErrorActionPreference = 'Stop'

function Write-LogHeader {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$EmulatorLabel,
        [Parameter(Mandatory = $true)][string]$ConfigLabel,
        [Parameter(Mandatory = $true)][string]$LogFile,
        [Parameter(Mandatory = $true)][string]$ProjectDir,
        [Parameter(Mandatory = $true)][string]$WorkingDir,
        [Parameter(Mandatory = $true)][string]$TargetFile,
        [string]$Platform
    )

    $lines = @(
        '===========================================',
        $Title,
        '===========================================',
        "Game: $GameName"
    )

    if ($Platform) {
        $lines += "Platform: $Platform"
    }

    $lines += @(
        "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "Project Directory: $ProjectDir",
        "Working Directory: $WorkingDir",
        "Target File: $TargetFile",
        "Emulator: $EmulatorLabel",
        "Config: $ConfigLabel",
        "Logfile: $LogFile",
        '===========================================',
        ''
    )

    Set-Content -LiteralPath $LogFile -Value $lines -Encoding ASCII
}

function Write-LogFooter {
    param(
        [Parameter(Mandatory = $true)][int]$ExitCode,
        [Parameter(Mandatory = $true)][string]$LogFile
    )

    Add-Content -LiteralPath $LogFile -Encoding ASCII -Value @(
        '',
        '===========================================',
        "Ended: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "Exit Code: $ExitCode",
        '==========================================='
    )
}

function Find-LocalExecutable {
    param(
        [Parameter(Mandatory = $true)][string]$FolderName,
        [Parameter(Mandatory = $true)][string[]]$CandidateNames,
        [Parameter(Mandatory = $true)][string]$EmulatorRoot
    )

    $folderPath = Join-Path $EmulatorRoot $FolderName
    if (-not (Test-Path -LiteralPath $folderPath)) {
        return $null
    }

    foreach ($candidate in $CandidateNames) {
        $candidatePath = Join-Path $folderPath $candidate
        if (Test-Path -LiteralPath $candidatePath) {
            return (Resolve-Path -LiteralPath $candidatePath).Path
        }
    }

    $fallback = Get-ChildItem -LiteralPath $folderPath -Filter '*.exe' -File -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($fallback) {
        return $fallback.FullName
    }

    return $null
}

function Find-CommandExecutable {
    param([Parameter(Mandatory = $true)][string[]]$CandidateNames)

    foreach ($candidate in $CandidateNames) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) {
            return $command.Source
        }
    }

    return $null
}

function Resolve-Emulator {
    param(
        [Parameter(Mandatory = $true)][string]$FolderName,
        [Parameter(Mandatory = $true)][string[]]$LocalCandidates,
        [Parameter(Mandatory = $true)][string[]]$PathCandidates,
        [Parameter(Mandatory = $true)][string]$EmulatorRoot,
        [Parameter(Mandatory = $true)][string]$Hint
    )

    $localPath = Find-LocalExecutable -FolderName $FolderName -CandidateNames $LocalCandidates -EmulatorRoot $EmulatorRoot
    if ($localPath) {
        return $localPath
    }

    $commandPath = Find-CommandExecutable -CandidateNames $PathCandidates
    if ($commandPath) {
        return $commandPath
    }

    throw "$Hint`nExpected folder: $FolderName under Configuration\\Emulators."
}

try {
    $ProjectDir = (Resolve-Path -LiteralPath $ProjectDir).Path
    $ResolvedTargetDir = Join-Path $ProjectDir $TargetDir
    $ResolvedTargetPath = Join-Path $ResolvedTargetDir $FileName
    $LogsDir = Join-Path $ProjectDir 'Logs'
    $EmulatorRoot = Join-Path $ProjectDir 'Configuration\Emulators'

    if (-not (Test-Path -LiteralPath $ResolvedTargetDir)) {
        throw "Target directory does not exist: $ResolvedTargetDir"
    }

    if (-not (Test-Path -LiteralPath $ResolvedTargetPath)) {
        throw "Target file does not exist: $ResolvedTargetPath"
    }

    New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null

    $logBaseName = if ($Mode -eq 'dos') { $GameName } else { "{0}_{1}" -f $Platform, $GameName }
    $LogFile = Join-Path $LogsDir ($logBaseName + '.log')
    $emulatorLabel = ''
    $configLabel = 'default'
    $workingDir = $ResolvedTargetDir
    $arguments = @()
    $emulatorPath = $null

    switch ($Mode) {
        'dos' {
            $configPath = Join-Path $ProjectDir 'Configuration\dosbox.conf'
            $localConfigPath = Join-Path $ResolvedTargetDir 'dosbox.conf'
            if (Test-Path -LiteralPath $localConfigPath) {
                $configPath = $localConfigPath
            }

            $emulatorPath = Resolve-Emulator -FolderName 'DOSBox' -LocalCandidates @('dosbox.exe') -PathCandidates @('dosbox.exe') -EmulatorRoot $EmulatorRoot -Hint 'DOSBox was not found.'
            $arguments = @($FileName, '-conf', $configPath, '-fullscreen', '-exit')
            $configLabel = $configPath
        }
        'rom' {
            if (-not $Platform) {
                throw 'Platform is required for ROM launchers.'
            }

            switch ($Platform) {
                'GB' {
                    $emulatorPath = Resolve-Emulator -FolderName 'mGBA' -LocalCandidates @('mGBA.exe', 'mgba-qt.exe') -PathCandidates @('mGBA.exe', 'mgba-qt.exe') -EmulatorRoot $EmulatorRoot -Hint 'mGBA was not found.'
                    $arguments = @($ResolvedTargetPath)
                }
                'GBA' {
                    $emulatorPath = Resolve-Emulator -FolderName 'mGBA' -LocalCandidates @('mGBA.exe', 'mgba-qt.exe') -PathCandidates @('mGBA.exe', 'mgba-qt.exe') -EmulatorRoot $EmulatorRoot -Hint 'mGBA was not found.'
                    $arguments = @($ResolvedTargetPath)
                }
                'PS1' {
                    $emulatorPath = Resolve-Emulator -FolderName 'DuckStation' -LocalCandidates @('duckstation-qt-x64-ReleaseLTCG.exe', 'duckstation-qt.exe', 'duckstation.exe', 'DuckStation.exe') -PathCandidates @('duckstation-qt-x64-ReleaseLTCG.exe', 'duckstation-qt.exe', 'duckstation.exe', 'DuckStation.exe') -EmulatorRoot $EmulatorRoot -Hint 'DuckStation was not found.'
                    $arguments = @($ResolvedTargetPath)
                }
                'PS2' {
                    $emulatorPath = Resolve-Emulator -FolderName 'PCSX2' -LocalCandidates @('pcsx2-qt.exe', 'pcsx2.exe') -PathCandidates @('pcsx2-qt.exe', 'pcsx2.exe') -EmulatorRoot $EmulatorRoot -Hint 'PCSX2 was not found.'
                    $arguments = @($ResolvedTargetPath)
                }
                'PSP' {
                    $emulatorPath = Resolve-Emulator -FolderName 'PPSSPP' -LocalCandidates @('PPSSPPWindows64.exe', 'PPSSPPQt.exe', 'PPSSPPWindows.exe', 'PPSSPP.exe') -PathCandidates @('PPSSPPWindows64.exe', 'PPSSPPQt.exe', 'PPSSPPWindows.exe', 'PPSSPP.exe') -EmulatorRoot $EmulatorRoot -Hint 'PPSSPP was not found.'
                    $arguments = @($ResolvedTargetPath)
                }
                'N64' {
                    $emulatorPath = Resolve-Emulator -FolderName 'Mupen64Plus' -LocalCandidates @('mupen64plus-ui-console.exe', 'mupen64plus.exe') -PathCandidates @('mupen64plus-ui-console.exe', 'mupen64plus.exe') -EmulatorRoot $EmulatorRoot -Hint 'Mupen64Plus was not found.'
                    $arguments = @('--fullscreen', '--configdir', (Join-Path $ProjectDir 'Configuration'), $ResolvedTargetPath)
                    $configLabel = Join-Path $ProjectDir 'Configuration\mupen64plus.cfg'
                }
                default {
                    throw "Unsupported ROM platform: $Platform"
                }
            }
        }
    }

    $emulatorLabel = $emulatorPath
    $title = if ($Mode -eq 'dos') { 'DOS LAUNCHER LOG' } else { "$Platform LAUNCHER LOG" }
    Write-LogHeader -Title $title -EmulatorLabel $emulatorLabel -ConfigLabel $configLabel -LogFile $LogFile -ProjectDir $ProjectDir -WorkingDir $workingDir -TargetFile $FileName -Platform $Platform

    Push-Location -LiteralPath $workingDir
    try {
        $global:LASTEXITCODE = 0
        & $emulatorPath @arguments 2>&1 | Tee-Object -FilePath $LogFile -Append | Out-Host
        $exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
    }
    finally {
        Pop-Location
    }

    Write-LogFooter -ExitCode $exitCode -LogFile $LogFile
    exit $exitCode
}
catch {
    $message = $_.Exception.Message
    Write-Error $message
    exit 1
}
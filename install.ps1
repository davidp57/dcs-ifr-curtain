<#
.SYNOPSIS
    Development install of the IFR curtain in DCS World (players use the Open Mod Manager
    package built by tools\build_omm.py instead).

.DESCRIPTION
    - Copies mod\Scripts\...\IFR_CURTAIN into the DCS install.
    - Adds one line to the shared kneeboard declaration, loaded by most modules; the curtain
      itself is then declared only for the aircraft listed in IFR_CURTAIN\shapes.lua.
    The key bindings are not installed here: they come from the Custom_Keybinds package
    (dcs-community-keybinds), through Quaggles' DCS Input Command Injector.

    The patched file is saved as <file>.ifr-curtain.bak before it is changed; the backup is
    refreshed whenever the file is found without the curtain (after a DCS update, say).
    A DCS update or repair overwrites the patched file: run this script again afterwards.
    After editing the mod, run it again and restart the mission: cockpit scripts are read at
    each mission start.

.EXAMPLE
    .\install.ps1
.EXAMPLE
    .\install.ps1 -Uninstall
.EXAMPLE
    .\install.ps1 -DcsPath "D:\DCS World"
#>
param(
    [string]$DcsPath = "C:\jeux\DCS World",
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

$Marker      = "IFR-CURTAIN"
$BackupExt   = ".ifr-curtain.bak"
$ModSource   = Join-Path $PSScriptRoot "mod\Scripts\Aircrafts\_Common\Cockpit\IFR_CURTAIN"
$ModTarget   = Join-Path $DcsPath "Scripts\Aircrafts\_Common\Cockpit\IFR_CURTAIN"
$DeclareFile = Join-Path $DcsPath "Scripts\Aircrafts\_Common\Cockpit\KNEEBOARD\declare_kneeboard_device.lua"

$Utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)

# Reads a file as UTF-8, remembering whether it starts with a byte order mark.
# Refuses a file that is not valid UTF-8 rather than rewriting it with replaced characters.
function Read-Text([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $start = if ($bom) { 3 } else { 0 }
    try {
        $text = $Utf8Strict.GetString($bytes, $start, $bytes.Length - $start)
    }
    catch {
        throw "Not valid UTF-8, left untouched: $Path"
    }
    return @{ Text = $text; Bom = $bom }
}

function Write-Text([string]$Path, [string]$Text, [bool]$Bom) {
    $encoding = New-Object System.Text.UTF8Encoding($Bom)
    [System.IO.File]::WriteAllText($Path, $Text, $encoding)
}

function Get-Newline([string]$Text) {
    if ($Text.Contains("`r`n")) { return "`r`n" }
    return "`n"
}

function Test-Block([string]$Text) {
    return $Text.Contains("-- $Marker BEGIN")
}

# Removes every block between the BEGIN and END markers, markers included, even when the
# block ends the file without a final newline.
function Remove-Block([string]$Text) {
    $pattern = "(?ms)^[ \t]*-- $Marker BEGIN.*?-- $Marker END[ \t]*(\r?\n|\z)"
    return [regex]::Replace($Text, $pattern, "")
}

# Appends the block at the end of the file.
function Set-Block([string]$Path, [string[]]$Lines) {
    $file = Read-Text $Path
    if (-not (Test-Block $file.Text)) {
        # The file is as DCS shipped it: (re)take the backup from it.
        Copy-Item -LiteralPath $Path -Destination ($Path + $BackupExt) -Force
    }
    $text = Remove-Block $file.Text
    $nl = Get-Newline $text
    if (-not $text.EndsWith("`n")) { $text += $nl }
    $text += "-- $Marker BEGIN$nl" + (($Lines | ForEach-Object { $_ + $nl }) -join "") + "-- $Marker END$nl"
    Write-Text $Path $text $file.Bom
    Write-Host "Patched: $Path"
}

function Clear-Block([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $file = Read-Text $Path
    if (-not (Test-Block $file.Text)) { return }
    $clean = Remove-Block $file.Text
    $backup = $Path + $BackupExt
    if (Test-Path -LiteralPath $backup) {
        # Installing may have added a final newline the original did not have: when only
        # trailing whitespace differs from the backup, put the backup back as it was.
        $original = Read-Text $backup
        if ($clean.TrimEnd() -ceq $original.Text.TrimEnd()) {
            Copy-Item -LiteralPath $backup -Destination $Path -Force
            Remove-Item -LiteralPath $backup -Force
            Write-Host "Restored: $Path"
            return
        }
    }
    Write-Text $Path $clean $file.Bom
    Write-Host "Cleaned: $Path"
}

if (-not (Test-Path -LiteralPath $DeclareFile)) {
    throw "DCS not found: $DeclareFile does not exist. Pass -DcsPath."
}

if ($Uninstall) {
    Clear-Block $DeclareFile
    if (Test-Path -LiteralPath $ModTarget) {
        Remove-Item -LiteralPath $ModTarget -Recurse -Force
        Write-Host "Removed: $ModTarget"
    }
    Write-Host "IFR curtain removed."
    return
}

if (Test-Path -LiteralPath $ModTarget) {
    Remove-Item -LiteralPath $ModTarget -Recurse -Force
}
Copy-Item -LiteralPath $ModSource -Destination $ModTarget -Recurse
Write-Host "Copied: $ModTarget"

Set-Block $DeclareFile @(
    'dofile(LockOn_Options.common_script_path.."IFR_CURTAIN/declare.lua")'
)

Write-Host "IFR curtain installed (key bindings: Custom_Keybinds package, through Quaggles' injector)."

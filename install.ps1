<#
.SYNOPSIS
    Development install of the IFR curtain in DCS World (players use the Open Mod Manager
    package built by tools\build_omm.py instead).

.DESCRIPTION
    - Copies mod\Scripts\...\IFR_CURTAIN into the DCS install.
    - Copies its declaration, COCKPIT_MODS\IFR_CURTAIN.lua, run by the shared cockpit mods
      hook (dcs-cockpit-mods: its install.ps1 -Part Hook, or the Cockpit_Mods_Hook package),
      which must be installed first. The curtain itself is then declared only for the
      aircraft listed in IFR_CURTAIN\shapes.lua.
    The key bindings are not installed here: they come from the Custom_Keybinds package
    (dcs-community-keybinds), through Quaggles' DCS Input Command Injector.

    Versions before the hook added their own line to the kneeboard declaration (between
    "-- IFR-CURTAIN BEGIN" and "-- IFR-CURTAIN END"): -Uninstall takes that
    line out, and puts the file back from its .ifr-curtain.bak backup when nothing else
    changed. Without that backup, the line most likely comes from an IFR_Curtain 1.x Open
    Mod Manager package: the script stops and asks to uninstall it there (-Force takes the
    line out anyway).
    After editing the mod, run this script again and restart the mission: cockpit scripts
    are read at each mission start.

.EXAMPLE
    .\install.ps1
.EXAMPLE
    .\install.ps1 -Uninstall
.EXAMPLE
    .\install.ps1 -DcsPath "D:\DCS World"
#>
param(
    [string]$DcsPath = "C:\jeux\DCS World",
    [switch]$Uninstall,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$LegacyMarker = "IFR-CURTAIN"
$LegacyBackupExt = ".ifr-curtain.bak"
$Cockpit      = Join-Path $DcsPath "Scripts\Aircrafts\_Common\Cockpit"
$ModSource    = Join-Path $PSScriptRoot "mod\Scripts\Aircrafts\_Common\Cockpit"
$ModTarget    = Join-Path $Cockpit "IFR_CURTAIN"
$DeclareTarget = Join-Path $Cockpit "COCKPIT_MODS\IFR_CURTAIN.lua"
$Loader       = Join-Path $Cockpit "COCKPIT_MODS\_loader.lua"
$KneeboardFile = Join-Path $Cockpit "KNEEBOARD\declare_kneeboard_device.lua"

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

# Takes out the line older versions added to the kneeboard declaration, if any.
function Clear-LegacyBlock([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $file = Read-Text $Path
    if (-not $file.Text.Contains("-- $LegacyMarker BEGIN")) { return }
    $pattern = "(?ms)^[ \t]*-- $LegacyMarker BEGIN.*?-- $LegacyMarker END[ \t]*(\r?\n|\z)"
    $clean = [regex]::Replace($file.Text, $pattern, "")
    $backup = $Path + $LegacyBackupExt
    if (-not (Test-Path -LiteralPath $backup)) {
        if (-not $Force) {
            # No backup of ours: the line most likely comes from an IFR_Curtain 1.x package,
            # and Open Mod Manager owns the file. It puts the original back on uninstall.
            throw "The kneeboard file holds the line of an IFR curtain 1.x without the backup this script makes ($Path): uninstall the IFR_Curtain 1.x package in Open Mod Manager, or, for a development install whose backup was lost, pass -Force."
        }
        Write-Text $Path $clean $file.Bom
        Write-Host "Cleaned (old curtain line taken out, no backup): $Path"
        return
    }
    # Installing may have added a final newline the original did not have: when only
    # trailing whitespace differs from the backup, put the backup back as it was.
    $original = Read-Text $backup
    if ($clean.TrimEnd() -ceq $original.Text.TrimEnd()) {
        Copy-Item -LiteralPath $backup -Destination $Path -Force
        Write-Host "Restored (old curtain line taken out): $Path"
    }
    else {
        Write-Text $Path $clean $file.Bom
        Write-Host "Cleaned (old curtain line taken out): $Path"
    }
    # Nothing else uses this backup any more.
    Remove-Item -LiteralPath $backup -Force
}

function Remove-IfPresent([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
        Write-Host "Removed: $Path"
    }
}

if (-not (Test-Path -LiteralPath $KneeboardFile)) {
    throw "DCS not found: $KneeboardFile does not exist. Pass -DcsPath."
}

if ($Uninstall) {
    Clear-LegacyBlock $KneeboardFile
    Remove-IfPresent $DeclareTarget
    Remove-IfPresent $ModTarget
    Write-Host "IFR curtain removed."
    return
}

# Checked before changing anything. The hook refuses to install over a 1.x line, so with the
# hook in place there is no 1.x line left to take out.
# Both halves: a DCS update or repair puts the kneeboard file back and leaves the loader.
if (-not (Test-Path -LiteralPath $Loader) -or -not (Read-Text $KneeboardFile).Text.Contains("COCKPIT_MODS/_loader.lua")) {
    throw "The cockpit mods hook is not installed ($Loader, and its line in $KneeboardFile). Coming from a 1.x development install: run this script with -Uninstall first. Then run dcs-cockpit-mods\install.ps1 -Part Hook (or install the Cockpit_Mods_Hook package), then this script again."
}

Remove-IfPresent $ModTarget
Copy-Item -LiteralPath (Join-Path $ModSource "IFR_CURTAIN") -Destination $ModTarget -Recurse
Write-Host "Copied: $ModTarget"
Copy-Item -LiteralPath (Join-Path $ModSource "COCKPIT_MODS\IFR_CURTAIN.lua") -Destination $DeclareTarget -Force
Write-Host "Copied: $DeclareTarget"

Write-Host "IFR curtain installed (key bindings: Custom_Keybinds package, through Quaggles' injector)."

<#
.SYNOPSIS
    Installs or removes the IFR curtain in DCS World.

.DESCRIPTION
    - Copies mod\Scripts\...\IFR_CURTAIN into the DCS install.
    - Adds one line to the shared kneeboard declaration, loaded by most modules; the curtain
      itself is then declared only for the aircraft listed in IFR_CURTAIN\shapes.lua.
    - Adds the curtain commands to the input files of the modules listed in $InputModules:
      keyboard and joystick default.lua, and the complete hardware profiles (HOTAS Warthog,
      X52...) built the same way. The *.diff.lua profiles inherit them from default.lua.
    Every patched file is saved as <file>.ifr-curtain.bak before it is changed; the backup is
    refreshed whenever the file is found without the curtain (after a DCS update, say).
    A DCS update or repair overwrites the patched files: run this script again afterwards.

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

# Modules whose input files get the curtain commands (folder under Mods\aircraft, input sub-folder).
# A module listed here must also have a shape in IFR_CURTAIN\shapes.lua.
$InputModules = @(
    @{ Module = "A-10C_2"; Input = "A-10C_2" }
)

$DeviceId = 250
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

# $Where: "end" to append the block, "return" to insert it before the last top-level return.
function Set-Block([string]$Path, [string[]]$Lines, [string]$Where) {
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Warning "Missing, skipped: $Path"
        return
    }
    $file = Read-Text $Path
    if (-not (Test-Block $file.Text)) {
        # The file is as DCS shipped it: (re)take the backup from it.
        Copy-Item -LiteralPath $Path -Destination ($Path + $BackupExt) -Force
    }
    $text = Remove-Block $file.Text
    $nl = Get-Newline $text
    $block = "-- $Marker BEGIN$nl" + (($Lines | ForEach-Object { $_ + $nl }) -join "") + "-- $Marker END$nl"

    if ($Where -eq "end") {
        if (-not $text.EndsWith("`n")) { $text += $nl }
        $text += $block
    }
    else {
        $returns = [regex]::Matches($text, "(?m)^return\b")
        if ($returns.Count -eq 0) {
            throw "No top-level 'return' found in $Path"
        }
        $index = $returns[$returns.Count - 1].Index
        $text = $text.Substring(0, $index) + $block + $text.Substring($index)
    }
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

# Input files of a module that build their commands in a local 'res' table and return its
# keyCommands: default.lua and the complete hardware profiles. Others are reported and skipped.
function Get-InputFiles($Entry) {
    $base = Join-Path $DcsPath ("Mods\aircraft\" + $Entry.Module + "\Input\" + $Entry.Input)
    $files = @()
    foreach ($kind in @("keyboard", "joystick")) {
        $folder = Join-Path $base $kind
        if (-not (Test-Path -LiteralPath $folder)) { continue }
        foreach ($f in Get-ChildItem -LiteralPath $folder -Filter "*.lua" -File) {
            if ($f.Name -like "*.diff.lua") { continue }
            $text = (Read-Text $f.FullName).Text
            $usesRes = ($text -match "(?m)^local res\b") -and
                       (($text -match "keyCommands\s*=\s*res\.keyCommands") -or ($text -match "(?m)^return res\b"))
            if ($usesRes) {
                $files += $f.FullName
            }
            else {
                Write-Host "No 'res' command table, skipped: $($f.FullName)"
            }
        }
    }
    return $files
}

if (-not (Test-Path -LiteralPath $DeclareFile)) {
    throw "DCS not found: $DeclareFile does not exist. Pass -DcsPath."
}

if ($Uninstall) {
    Clear-Block $DeclareFile
    foreach ($entry in $InputModules) {
        foreach ($path in Get-InputFiles $entry) { Clear-Block $path }
    }
    if (Test-Path -LiteralPath $ModTarget) {
        Remove-Item -LiteralPath $ModTarget -Recurse -Force
        Write-Host "Removed: $ModTarget"
    }
    Write-Host "IFR curtain removed."
    return
}

# 1. Mod files
if (Test-Path -LiteralPath $ModTarget) {
    Remove-Item -LiteralPath $ModTarget -Recurse -Force
}
Copy-Item -LiteralPath $ModSource -Destination $ModTarget -Recurse
Write-Host "Copied: $ModTarget"

# 2. Shared kneeboard declaration (the curtain then declares itself for the aircraft it knows)
Set-Block $DeclareFile @(
    'dofile(LockOn_Options.common_script_path.."IFR_CURTAIN/declare.lua")'
) "end"

# 3. Input commands
foreach ($entry in $InputModules) {
    foreach ($path in Get-InputFiles $entry) {
        Set-Block $path @(
            "res.keyCommands[#res.keyCommands + 1] = {down = 3001, cockpit_device_id = $DeviceId, value_down = 1.0, name = _('IFR curtain: toggle'), category = _('IFR curtain')}",
            "res.keyCommands[#res.keyCommands + 1] = {down = 3002, cockpit_device_id = $DeviceId, value_down = 1.0, name = _('IFR curtain: close'), category = _('IFR curtain')}",
            "res.keyCommands[#res.keyCommands + 1] = {down = 3003, cockpit_device_id = $DeviceId, value_down = 1.0, name = _('IFR curtain: open'), category = _('IFR curtain')}"
        ) "return"
    }
}

Write-Host "IFR curtain installed. Bind 'IFR curtain: toggle' in Options > Controls (category 'IFR curtain')."

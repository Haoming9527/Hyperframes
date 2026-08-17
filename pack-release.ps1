$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

$Name = "Hyperframes-local-kit-0.7.94"
$Stage = Join-Path $env:TEMP $Name
$OutDir = Join-Path $PSScriptRoot "dist"
$Out = Join-Path $OutDir "$Name.zip"

function Write-Bar {
  param(
    [int]$Percent,
    [string]$Status,
    [string]$Elapsed = ""
  )
  $width = 32
  $pct = [Math]::Max(0, [Math]::Min(100, $Percent))
  $fill = [int][Math]::Round($width * $pct / 100.0)
  $bar = ("#" * $fill).PadRight($width, "-")
  $line = "  [{0}] {1,3}%  {2}" -f $bar, $pct, $Status
  if ($Elapsed) { $line += "  $Elapsed" }
  $pad = [Math]::Max(0, 110 - $line.Length)
  [Console]::Write("`r" + $line + (" " * $pad))
}

function Format-Elapsed([datetime]$start) {
  $t = (Get-Date) - $start
  "{0:mm\:ss}" -f [TimeSpan]::FromSeconds([int]$t.TotalSeconds)
}

function Wait-While {
  param(
    [scriptblock]$StillRunning,
    [int]$From,
    [int]$To,
    [string]$Label,
    [datetime]$Start,
    [scriptblock]$ExtraStatus
  )
  while (& $StillRunning) {
    $elapsed = ((Get-Date) - $Start).TotalSeconds
    $pct = $From + [int](($To - $From - 1) * (1 - [Math]::Exp(-$elapsed / 45.0)))
    if ($pct -lt $From) { $pct = $From }
    if ($pct -gt ($To - 1)) { $pct = $To - 1 }
    $status = $Label
    if ($ExtraStatus) {
      $extra = & $ExtraStatus
      if ($extra) { $status = "$Label  $extra" }
    }
    Write-Bar -Percent $pct -Status $status -Elapsed (Format-Elapsed $Start)
    Start-Sleep -Milliseconds 250
  }
}

Write-Host ""
Write-Host "Packing $Name"
Write-Host "Close the zip in Explorer / Cursor if it is open, or the write will stall."
Write-Host ""

if (Test-Path -LiteralPath $Stage) {
  Write-Bar -Percent 2 -Status "Clearing previous stage..."
  Remove-Item -LiteralPath $Stage -Recurse -Force
}
New-Item -ItemType Directory -Path $Stage | Out-Null
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$copyStart = Get-Date
$robocopy = Start-Process -FilePath "robocopy.exe" -ArgumentList @(
  ".", $Stage, "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/MT:8", "/R:1", "/W:1",
  "/XD", "research", "renders", "pitch-video", "video-material", "pitch-deck",
  "videos", "dist", ".git", "packages", "snapshots", ".hyperframes",
  "/XF", "*.mp4", "*.webm", "*.mov", ".env"
) -NoNewWindow -PassThru

Wait-While -StillRunning { -not $robocopy.HasExited } -From 3 -To 74 -Label "Copying files..." -Start $copyStart
$robocopy.WaitForExit()
if ($robocopy.ExitCode -ge 8) {
  Write-Host ""
  Write-Error "robocopy failed, exit $($robocopy.ExitCode)"
  exit 1
}
Write-Bar -Percent 75 -Status "Copy complete." -Elapsed (Format-Elapsed $copyStart)
Write-Host ""

if (Test-Path -LiteralPath $Out) {
  try {
    Remove-Item -LiteralPath $Out -Force -ErrorAction Stop
  } catch {
    Write-Host ""
    Write-Error "Cannot overwrite the zip. Close dist\$Name.zip in Cursor/Explorer, then run pack-release.cmd again."
    exit 1
  }
}

$zipStart = Get-Date
$job = Start-Job -ScriptBlock {
  param($stage, $out)
  Add-Type -AssemblyName System.IO.Compression
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::CreateFromDirectory(
    $stage,
    $out,
    [IO.Compression.CompressionLevel]::Fastest,
    $false
  )
} -ArgumentList $Stage, $Out

Wait-While `
  -StillRunning { $job.State -eq "Running" } `
  -From 76 -To 96 `
  -Label "Writing zip..." `
  -Start $zipStart `
  -ExtraStatus {
    if (Test-Path -LiteralPath $Out) {
      $mb = [Math]::Round((Get-Item -LiteralPath $Out).Length / 1MB, 0)
      "$mb MB"
    }
  }

Receive-Job -Job $job -ErrorAction Stop | Out-Null
Remove-Job -Job $job -Force | Out-Null
Write-Bar -Percent 96 -Status "Zip written." -Elapsed (Format-Elapsed $zipStart)
Write-Host ""

Write-Bar -Percent 97 -Status "Cleaning stage..."
Remove-Item -LiteralPath $Stage -Recurse -Force
Write-Bar -Percent 100 -Status "Done."
Write-Host ""
Write-Host ""

$item = Get-Item -LiteralPath $Out
$sizeMb = [Math]::Round($item.Length / 1MB, 1)
Write-Host ("Packed: {0}  ({1} MB)" -f $item.FullName, $sizeMb)
exit 0

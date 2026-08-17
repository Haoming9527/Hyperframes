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
  $pad = [Math]::Max(0, 100 - $line.Length)
  Write-Host ("`r" + $line + (" " * $pad)) -NoNewline
}

function Format-Elapsed([datetime]$start) {
  $t = (Get-Date) - $start
  "{0:mm\:ss}" -f [TimeSpan]::FromSeconds([int]$t.TotalSeconds)
}

function Wait-ProcessBar {
  param(
    [Diagnostics.Process]$Process,
    [int]$From,
    [int]$To,
    [string]$Label,
    [datetime]$Start
  )
  while (-not $Process.HasExited) {
    $elapsed = ((Get-Date) - $Start).TotalSeconds
    $pct = $From + [int](($To - $From - 1) * (1 - [Math]::Exp(-$elapsed / 35.0)))
    if ($pct -lt $From) { $pct = $From }
    if ($pct -gt ($To - 1)) { $pct = $To - 1 }
    Write-Bar -Percent $pct -Status $Label -Elapsed (Format-Elapsed $Start)
    Start-Sleep -Milliseconds 180
  }
  $Process.WaitForExit()
  return $Process.ExitCode
}

Write-Host ""
Write-Host "Packing $Name"
Write-Host ""

if (Test-Path -LiteralPath $Stage) {
  Write-Bar -Percent 2 -Status "Clearing previous stage..."
  Remove-Item -LiteralPath $Stage -Recurse -Force
}
New-Item -ItemType Directory -Path $Stage | Out-Null
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$copyStart = Get-Date
$robocopy = Start-Process -FilePath "robocopy.exe" -ArgumentList @(
  ".", $Stage, "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/R:1", "/W:1",
  "/XD", "research", "renders", "pitch-video", "video-material", "pitch-deck",
  "videos", "dist", ".git", "packages", "snapshots", ".hyperframes",
  "/XF", "*.mp4", "*.webm", "*.mov", ".env"
) -NoNewWindow -PassThru

$copyExit = Wait-ProcessBar -Process $robocopy -From 3 -To 74 -Label "Copying files..." -Start $copyStart
if ($copyExit -ge 8) {
  Write-Host ""
  Write-Error "robocopy failed, exit $copyExit"
  exit 1
}
Write-Bar -Percent 75 -Status "Copy complete." -Elapsed (Format-Elapsed $copyStart)
Write-Host ""

if (Test-Path -LiteralPath $Out) {
  Remove-Item -LiteralPath $Out -Force
}

$zipStart = Get-Date
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Write-Bar -Percent 80 -Status "Writing zip..." -Elapsed (Format-Elapsed $zipStart)
try {
  [IO.Compression.ZipFile]::CreateFromDirectory(
    $Stage,
    $Out,
    [IO.Compression.CompressionLevel]::Optimal,
    $false
  )
} catch {
  Write-Host ""
  Write-Error "zip failed: $($_.Exception.Message)"
  exit 1
}
Write-Bar -Percent 96 -Status "Zip written." -Elapsed (Format-Elapsed $zipStart)
Write-Host ""

Write-Bar -Percent 97 -Status "Cleaning stage..." -Elapsed (Format-Elapsed $zipStart)
Write-Host ""

Remove-Item -LiteralPath $Stage -Recurse -Force
Write-Bar -Percent 100 -Status "Done."
Write-Host ""
Write-Host ""

$item = Get-Item -LiteralPath $Out
$sizeMb = [Math]::Round($item.Length / 1MB, 1)
Write-Host ("Packed: {0}  ({1} MB)" -f $item.FullName, $sizeMb)
exit 0

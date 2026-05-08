$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $root "src"
$distDir = Join-Path $root "dist"
$outFile = Join-Path $distDir "ChillyScript.lua"

New-Item -ItemType Directory -Force -Path $distDir | Out-Null

$output = New-Object System.Collections.Generic.List[string]
Get-ChildItem -LiteralPath $srcDir -Filter "*.lua" | Sort-Object Name | ForEach-Object {
    $output.Add("-- ============================================================================")
    $output.Add("-- $($_.Name)")
    $output.Add("-- ============================================================================")
    $output.AddRange([string[]](Get-Content -LiteralPath $_.FullName))
    $output.Add("")
}

$encoding = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($outFile, [string[]]$output, $encoding)
Write-Host "Built $outFile"

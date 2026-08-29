#!/usr/bin/env pwsh
# Fetch YOLO-World ONNX models (s/m/l) from HuggingFace
# Usage: ./scripts/fetch-yoloworld.ps1 [-Tier s|m|l]
#
# Output:
#   utils-support-models-onnx-yoloworld-{s,m,l}/src/main/resources/vision/detection/yoloworld/
#     - yolov8s-worldv2.onnx  (~51MB)
#     - yolov8m-world.onnx   (~70MB)
#     - yolov8l-world.onnx   (~130MB)

[CmdletBinding()]
param(
    [ValidateSet("s","m","l")]
    [string]$Tier = "s",
    [string]$BaseUrl = "https://huggingface.co/onnx-community"
)

$ErrorActionPreference = "Stop"

$models = @{
    "s" = @{ Name="yolov8s-worldv2.onnx"; Repo="YOLOWorld-s"; Path="onnx/model.onnx"; SizeMB=51 }
    "m" = @{ Name="yolov8m-world.onnx";  Repo="YOLOWorld-m"; Path="onnx/model.onnx"; SizeMB=70 }
    "l" = @{ Name="yolov8l-world.onnx";  Repo="YOLOWorld-l"; Path="onnx/model.onnx"; SizeMB=130 }
}

$baseDir = Join-Path $PSScriptRoot "..\utils-support-models-onnx-yoloworld-$Tier"
$destDir = Join-Path $baseDir "src\main\resources\vision\detection\yoloworld"
$dest = Join-Path $destDir $models[$Tier].Name

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

if (Test-Path $dest) {
    $size = [math]::Round((Get-Item $dest).Length / 1MB, 1)
    Write-Host "Model already exists: $dest ($size MB)"
    exit 0
}

$downloadUrl = "$BaseUrl/$($models[$Tier].Repo)/resolve/main/$($models[$Tier].Path)"
Write-Host "Downloading $Tier model from: $downloadUrl"

$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "Mozilla/5.0")

try {
    $wc.DownloadFile($downloadUrl, $dest)
    $size = [math]::Round((Get-Item $dest).Length / 1MB, 1)
    Write-Host "Downloaded: $dest ($size MB)"
} catch {
    Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Try mirror: $( $downloadUrl -replace 'huggingface\.co', 'hf-mirror.com' )"
    throw
}
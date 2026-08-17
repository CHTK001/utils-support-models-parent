#!/usr/bin/env pwsh
# 获取 utils-support-models-onnx-faceplugin-detect-slim 模块的 ONNX 模型文件（face_detect_slim.onnx）。
#
# 用法:
#   ./scripts/fetch-faceplugin-detect-slim.ps1
#   ./scripts/fetch-faceplugin-detect-slim.ps1 -Url "<face_detect_slim.onnx 直链>"
#
# 输出:
#   utils-support-models-onnx-faceplugin-detect-slim/src/main/resources/models/onnx/face/detection/faceplugin/face_detect_slim.onnx
#
# 来源: Faceplugin-ltd/Open-Source-Face-Recognition-SDK

[CmdletBinding()]
param(
    [string]$Url
)

$ErrorActionPreference = "Stop"
$destDir = Join-Path $PSScriptRoot "..\utils-support-models-onnx-faceplugin-detect-slim\src\main\resources\models\onnx\face\detection\faceplugin"
$dest = Join-Path $destDir "face_detect_slim.onnx"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

if (-not $Url) {
    $Url = "https://github.com/Faceplugin-ltd/Open-Source-Face-Recognition-SDK/raw/master/onnx/face_detect_slim.onnx"
}

Write-Host "==> 下载 FacePlugin Slim Face Detection ONNX 模型" -ForegroundColor Green
Write-Host "    Target: $dest"

try {
    Invoke-WebRequest -Uri $Url -OutFile $dest -UseBasicParsing -TimeoutSec 600
    $size = (Get-Item $dest).Length
    Write-Host "==> 完成: $size bytes" -ForegroundColor Green
    if ($size -lt 1MB) {
        Write-Warning "文件过小，可能不是有效 ONNX 模型，请检查 URL"
    }
} catch {
    Write-Host "==> 下载失败: $_" -ForegroundColor Red
    Write-Host "请手动下载后放置: $dest"
    exit 1
}
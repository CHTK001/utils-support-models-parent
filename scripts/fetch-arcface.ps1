#!/usr/bin/env pwsh
# 获取 utils-support-models-onnx-arcface 模块的 ONNX 模型文件（w600k_r50.onnx）。
#
# 用法:
#   ./scripts/fetch-arcface.ps1
#   ./scripts/fetch-arcface.ps1 -Url "<w600k_r50.onnx 直链>"
#
# 输出:
#   utils-support-models-onnx-arcface/src/main/resources/face/swap/common/buffalo_l/w600k_r50.onnx
#
# 绑定有效 Maven 仓库前请先执行此脚本。

[CmdletBinding()]
param(
    [string]$Url
)

$ErrorActionPreference = "Stop"
$destDir = Join-Path $PSScriptRoot "..\utils-support-models-onnx-arcface\src\main\resources\face\swap\common\buffalo_l"
$dest = Join-Path $destDir "w600k_r50.onnx"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

if (-not $Url) {
    $Url = "https://github.com/deepinsight/insightface/releases/download/v0.7/buffalo_l.zip"
    Write-Warning "默认源是 buffalo_l.zip（内含 w600k_r50.onnx），需先解压提取后再放到目标目录；也可用 -Url 指定 w600k_r50.onnx 直链"
    Write-Warning "GitHub 直连可能很慢，建议使用代理或手动下载：https://github.com/deepinsight/insightface/releases/download/v0.7/buffalo_l.zip"
}

Write-Host "==> 下载 ArcFace w600k_r50 ONNX 模型" -ForegroundColor Green
Write-Host "    Target: $dest"

if ($Url -match "buffalo_l\.zip$") {
    $tmp = Join-Path $env:TEMP "buffalo_l.zip"
    Invoke-WebRequest -Uri $Url -OutFile $tmp -UseBasicParsing -TimeoutSec 600
    Expand-Archive -Path $tmp -DestinationPath (Join-Path $env:TEMP "buffalo_l") -Force
    Copy-Item (Join-Path $env:TEMP "buffalo_l\w600k_r50.onnx") $dest
} else {
    Invoke-WebRequest -Uri $Url -OutFile $dest -UseBasicParsing -TimeoutSec 600
}

$size = (Get-Item $dest).Length
Write-Host "==> 完成: $size bytes" -ForegroundColor Green
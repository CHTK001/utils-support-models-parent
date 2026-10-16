#!/usr/bin/env pwsh
# 拉取 utils-support-models-onnx-ppe 所需的 ONNX 模型文件。
#
# 用法:
#   ./scripts/fetch-ppe.ps1
#   ./scripts/fetch-ppe.ps1 -Url "https://example.com/model.onnx"
#
# 输出:
#   utils-support-models-onnx-ppe/src/main/resources/vision/ppe/yolov8n/model.onnx
#
# 部署到云效 Maven 仓库前必须执行此脚本。

[CmdletBinding()]
param(
    [string]$Url
)

$ErrorActionPreference = "Stop"
$destDir = Join-Path $PSScriptRoot "..\utils-support-models-onnx-ppe\src\main\resources\vision\ppe\yolov8n"
$dest = Join-Path $destDir "model.onnx"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

if (-not $Url) {
    $Url = "https://huggingface.co/keremberke/yolov8n-hard-hat-detection/resolve/main/best.pt"
    Write-Warning "使用默认源（实际是 .pt 而非 .onnx），需先转换：yolo export model=best.pt format=onnx imgsz=640"
    Write-Warning "或显式指定 -Url 参数指向已转换的 .onnx URL"
}

Write-Host "==> 下载 PPE Detection YOLOv8n ONNX 模型" -ForegroundColor Green
Write-Host "    Source: $Url"
Write-Host "    Target: $dest"

try {
    Invoke-WebRequest -Uri $Url -OutFile $dest -UseBasicParsing -TimeoutSec 600
    $size = (Get-Item $dest).Length
    Write-Host "==> 下载完成: $size bytes" -ForegroundColor Green
    if ($size -lt 1MB) {
        Write-Warning "文件大小 < 1MB，可能不是有效的 ONNX 模型（YOLOv8n ppe ~6MB）。请检查 URL。"
    }
} catch {
    Write-Host "==> 下载失败: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "备选方案:" -ForegroundColor Yellow
    Write-Host "  1. 手动下载 (浏览器/Curl) 后放入: $dest"
    Write-Host "  2. 训练自定义: yolo detect train data=ppe.yaml model=yolov8n.pt epochs=100"
    Write-Host "  3. 转换已有 .pt: yolo export model=best.pt format=onnx imgsz=640"
    exit 1
}

Write-Host ""
Write-Host "==> 后续步骤:" -ForegroundColor Green
Write-Host "  cd utils-support-models-parent"
Write-Host "  mvn install -pl utils-support-models-onnx-ppe -am -DskipTests"
Write-Host ""

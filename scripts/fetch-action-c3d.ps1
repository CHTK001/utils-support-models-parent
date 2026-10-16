#!/usr/bin/env pwsh
# 拉取 utils-support-models-onnx-action-c3d 所需的 ONNX 模型文件。
#
# 用法:
#   ./scripts/fetch-action-c3d.ps1
#
# 输出:
#   utils-support-models-onnx-action-c3d/src/main/resources/vision/action/c3d/model.onnx
#
# 部署到云效 Maven 仓库前必须执行此脚本。

$ErrorActionPreference = "Stop"
$destDir = Join-Path $PSScriptRoot "..\utils-support-models-onnx-action-c3d\src\main\resources\vision\action\c3d"
$dest = Join-Path $destDir "model.onnx"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

$Url = "https://www.modelscope.cn/api/v1/models/iic/cv_ResNetC3D_action-detection_detection2d/repo?Revision=master&FilePath=model.onnx"
Write-Host "==> 下载 C3D Action Detection ONNX 模型 (ResNetC3D, 9 classes, ~95.5MB)" -ForegroundColor Green
Write-Host "    Source: $Url"
Write-Host "    Target: $dest"

try {
    Invoke-WebRequest -Uri $Url -OutFile $dest -UseBasicParsing -TimeoutSec 600
    $size = (Get-Item $dest).Length
    Write-Host "==> 下载完成: $size bytes" -ForegroundColor Green
    if ($size -lt 10MB) {
        Write-Warning "文件大小 < 10MB，可能不是有效的 ONNX 模型（预期 ~95.5MB）。请检查 URL。"
    }
} catch {
    Write-Host "==> 下载失败: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "备选方案:" -ForegroundColor Yellow
    Write-Host "  1. 手动下载 (浏览器/Curl) 后放入: $dest"
    Write-Host "  2. 使用 git lfs: git clone https://www.modelscope.cn/iic/cv_ResNetC3D_action-detection_detection2d.git"
    exit 1
}

Write-Host ""
Write-Host "==> 后续步骤:" -ForegroundColor Green
Write-Host "  cd utils-support-models-parent"
Write-Host "  mvn install -pl utils-support-models-onnx-action-c3d -am -DskipTests"
#!/usr/bin/env pwsh
# 拉取 utils-support-models-onnx-seal-inspection 所需的 ONNX 模型文件。
#
# 用法:
#   ./scripts/fetch-seal-inspection.ps1
#
# 输出:
#   utils-support-models-onnx-seal-inspection/src/main/resources/vision/detection/seal/model.onnx

$ErrorActionPreference = "Stop"
$destDir = Join-Path $PSScriptRoot "..\utils-support-models-onnx-seal-inspection\src\main\resources\vision\detection\seal"
$dest = Join-Path $destDir "model.onnx"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

$Url = "https://www.modelscope.cn/api/v1/models/SDT/Seal_inspection/repo?Revision=master&FilePath=best.pt"
Write-Host "==> 下载 SDT 印章检测 YOLO (640 输入，4 类) ONNX 模型 (需 yolo export，已内嵌约 42MB)" -ForegroundColor Green
Write-Host "    注意: 仓库为 best.pt (PyTorch)，需先用 yolo export（见 onnx convert 已完成并内嵌）"
Write-Host "    Target: $dest"
if (Test-Path $dest) {
    Write-Host ("==> 已存在: {0} bytes" -f (Get-Item $dest).Length) -ForegroundColor Green
}
Write-Host ""
Write-Host "==> 如需刷新，先执行 yolo export:" -ForegroundColor Yellow
Write-Host "  yolo export model=best.pt format=onnx imgsz=640"
Write-Host "  cd utils-support-models-parent"
Write-Host "  mvn install -pl utils-support-models-onnx-seal-inspection -am -DskipTests"
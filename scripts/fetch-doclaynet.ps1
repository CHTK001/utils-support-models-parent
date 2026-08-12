#!/usr/bin/env pwsh
# 拉取 utils-support-models-onnx-doclaynet 所需的 ONNX 模型文件。
#
# 用法:
#   ./scripts/fetch-doclaynet.ps1                          # 默认源
#   ./scripts/fetch-doclaynet.ps1 -Url "...custom.onnx"    # 自定义源
#   ./scripts/fetch-doclaynet.ps1 -Mirror hf-mirror        # 用 HF 镜像
#
# 输出:
#   utils-support-models-onnx-doclaynet/src/main/resources/vision/layout/doclaynet/model.onnx
#
# 部署到云效 Maven 仓库前必须执行此脚本。

[CmdletBinding()]
param(
    [string]$Url,
    [string]$Mirror = "huggingface"
)

$ErrorActionPreference = "Stop"
$destDir = Join-Path $PSScriptRoot "..\utils-support-models-onnx-doclaynet\src\main\resources\vision\layout\doclaynet"
$dest = Join-Path $destDir "model.onnx"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

if (-not $Url) {
    switch ($Mirror) {
        "huggingface" {
            $Url = "https://huggingface.co/foduucom/document-layout-analysis/resolve/main/models/yolov8s_doclaynet_imgsz640.onnx"
        }
        "hf-mirror" {
            $Url = "https://hf-mirror.com/foduucom/document-layout-analysis/resolve/main/models/yolov8s_doclaynet_imgsz640.onnx"
        }
        default {
            throw "未知 mirror: $Mirror"
        }
    }
}

# 备用源（如果主源失败，可手动 -Url 切换）
#   https://huggingface.co/onnx-community/yolov8-doclaynet-ONNX/resolve/main/onnx/model.onnx
#   https://huggingface.co/datasets/dermatologist/digit-recognition/resolve/main/model.onnx
#   https://github.com/opendatalab/DocLayout-YOLO/releases/download/v1.0/doclayout_yolo_docstructbench_imgsz1024.onnx (~40MB, 大)

Write-Host "==> 下载 DocLayNet YOLOv8 ONNX 模型" -ForegroundColor Green
Write-Host "    Source: $Url"
Write-Host "    Target: $dest"

# 代理设置（如果需要）
# $env:HTTPS_PROXY = "http://127.0.0.1:7890"

try {
    Invoke-WebRequest -Uri $Url -OutFile $dest -UseBasicParsing -TimeoutSec 600
    $size = (Get-Item $dest).Length
    Write-Host "==> 下载完成: $size bytes" -ForegroundColor Green
    if ($size -lt 1MB) {
        Write-Warning "文件大小 < 1MB，可能不是有效的 ONNX 模型。请检查 URL。"
    }
} catch {
    Write-Host "==> 下载失败: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "备选方案:" -ForegroundColor Yellow
    Write-Host "  1. 手动下载 (浏览器/Curl) 后放入: $dest"
    Write-Host "  2. 切换镜像: ./scripts/fetch-doclaynet.ps1 -Mirror hf-mirror"
    Write-Host "  3. 训练自定义: https://github.com/opendatalab/DocLayout-YOLO"
    exit 1
}

Write-Host ""
Write-Host "==> 后续步骤:" -ForegroundColor Green
Write-Host "  cd utils-support-models-parent"
Write-Host "  mvn install -pl utils-support-models-onnx-doclaynet -am -DskipTests"
Write-Host ""

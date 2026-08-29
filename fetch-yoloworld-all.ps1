#!/usr/bin/env pwsh
# Batch download all YOLO-World tiers
# Usage: ./scripts/fetch-yoloworld-all.ps1

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$tiers = @("s", "m", "l")
$scriptDir = $PSScriptRoot

foreach ($tier in $tiers) {
    Write-Host "`n===== Downloading YOLO-World tier: $tier =====" -ForegroundColor Cyan
    & "$scriptDir\fetch-yoloworld.ps1" -Tier $tier
}

Write-Host "`n===== All downloads complete =====" -ForegroundColor Green
Write-Host "Models location:"
Write-Host "  s: utils-support-models-onnx-yoloworld-s/src/main/resources/vision/detection/yoloworld/yolov8s-worldv2.onnx"
Write-Host "  m: utils-support-models-onnx-yoloworld-m/src/main/resources/vision/detection/yoloworld/yolov8m-world.onnx"
Write-Host "  l: utils-support-models-onnx-yoloworld-l/src/main/resources/vision/detection/yoloworld/yolov8l-world.onnx"
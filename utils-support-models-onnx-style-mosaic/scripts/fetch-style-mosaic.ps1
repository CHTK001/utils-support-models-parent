# fetch-style-mosaic.ps1
# 下载 Fast Neural Style Transfer - Mosaic（马赛克）ONNX 模型
# 模型大小约 6.6MB
# 来源: https://github.com/onnx/models/tree/main/validated/vision/style_transfer/fast_neural_style

$ErrorActionPreference = "Stop"
$BaseDir = Split-Path -Parent $PSScriptRoot
$OutDir = Join-Path $BaseDir "src\main\resources\vision\style_transfer\fast_neural_style"

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$ModelName = "mosaic-9.onnx"
$OutFile = Join-Path $OutDir $ModelName
$Url = "https://github.com/onnx/models/raw/main/validated/vision/style_transfer/fast_neural_style/model/$ModelName"

if (Test-Path $OutFile) {
    Write-Host "已存在: $ModelName [Mosaic 马赛克]" -ForegroundColor Green
    exit 0
}

Write-Host "下载: $ModelName [Mosaic 马赛克]..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
    $Size = (Get-Item $OutFile).Length / 1MB
    Write-Host "完成: $ModelName ($([math]::Round($Size, 1)) MB)" -ForegroundColor Green
} catch {
    Write-Host "失败: $ModelName - $_" -ForegroundColor Red
    if (Test-Path $OutFile) { Remove-Item $OutFile -Force }
    exit 1
}
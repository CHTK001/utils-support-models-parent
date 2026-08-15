# fetch-animegan-face-portrait.ps1
# 下载 AnimeGANv2 - Face Portrait V2（人像动漫化）ONNX 模型
# 模型大小约 8.6MB
# 来源: https://huggingface.co/akhaliq/AnimeGANv2-ONNX

$ErrorActionPreference = "Stop"
$BaseDir = Split-Path -Parent $PSScriptRoot
$OutDir = Join-Path $BaseDir "src\main\resources\vision\style_transfer\animegan2"

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$RemoteName = "face_paint_512_v2_0.onnx"
$ModelName = "face_portrait_v2.onnx"
$OutFile = Join-Path $OutDir $ModelName
$Url = "https://huggingface.co/akhaliq/AnimeGANv2-ONNX/resolve/main/$RemoteName"

if (Test-Path $OutFile) {
    Write-Host "已存在: $ModelName [Face Portrait V2 人像动漫化]" -ForegroundColor Green
    exit 0
}

Write-Host "下载: $RemoteName -> $ModelName [Face Portrait V2 人像动漫化]..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
    $Size = (Get-Item $OutFile).Length / 1MB
    Write-Host "完成: $ModelName ($([math]::Round($Size, 1)) MB)" -ForegroundColor Green
} catch {
    Write-Host "失败: $ModelName - $_" -ForegroundColor Red
    if (Test-Path $OutFile) { Remove-Item $OutFile -Force }
    exit 1
}
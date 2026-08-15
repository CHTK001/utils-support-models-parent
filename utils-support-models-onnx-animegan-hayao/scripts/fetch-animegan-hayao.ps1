# fetch-animegan-hayao.ps1
# 下载 AnimeGANv2 - Hayao（宫崎骏）ONNX 模型
# 模型大小约 8.6MB
# 来源: https://huggingface.co/vumichien/AnimeGANv2_Hayao (Apache-2.0)

$ErrorActionPreference = "Stop"
$BaseDir = Split-Path -Parent $PSScriptRoot
$OutDir = Join-Path $BaseDir "src\main\resources\vision\style_transfer\animegan2"

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$RemoteName = "AnimeGANv2_Hayao.onnx"
$ModelName = "hayao.onnx"
$OutFile = Join-Path $OutDir $ModelName
$Url = "https://huggingface.co/vumichien/AnimeGANv2_Hayao/resolve/main/$RemoteName"

if (Test-Path $OutFile) {
    Write-Host "已存在: $ModelName [Hayao 宫崎骏]" -ForegroundColor Green
    exit 0
}

Write-Host "下载: $RemoteName -> $ModelName [Hayao 宫崎骏]..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
    $Size = (Get-Item $OutFile).Length / 1MB
    Write-Host "完成: $ModelName ($([math]::Round($Size, 1)) MB)" -ForegroundColor Green
} catch {
    Write-Host "失败: $ModelName - $_" -ForegroundColor Red
    if (Test-Path $OutFile) { Remove-Item $OutFile -Force }
    exit 1
}
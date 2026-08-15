# fetch-animegan-shinkai.ps1
# 下载 AnimeGANv2 - Shinkai（新海诚）ONNX 模型
# 模型大小约 8.6MB
# 来源: https://huggingface.co/vumichien/AnimeGANv2_Shinkai (Apache-2.0)

$ErrorActionPreference = "Stop"
$BaseDir = Split-Path -Parent $PSScriptRoot
$OutDir = Join-Path $BaseDir "src\main\resources\vision\style_transfer\animegan2"

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$RemoteName = "AnimeGANv2_Shinkai.onnx"
$ModelName = "shinkai.onnx"
$OutFile = Join-Path $OutDir $ModelName
$Url = "https://huggingface.co/vumichien/AnimeGANv2_Shinkai/resolve/main/$RemoteName"

if (Test-Path $OutFile) {
    Write-Host "已存在: $ModelName [Shinkai 新海诚]" -ForegroundColor Green
    exit 0
}

Write-Host "下载: $RemoteName -> $ModelName [Shinkai 新海诚]..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
    $Size = (Get-Item $OutFile).Length / 1MB
    Write-Host "完成: $ModelName ($([math]::Round($Size, 1)) MB)" -ForegroundColor Green
} catch {
    Write-Host "失败: $ModelName - $_" -ForegroundColor Red
    if (Test-Path $OutFile) { Remove-Item $OutFile -Force }
    exit 1
}
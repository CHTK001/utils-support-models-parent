#!/usr/bin/env pwsh
# 获取 utils-support-models-onnx-paraformer-zh-small 模块的 ONNX 模型文件
# （pengzhendong/sherpa-onnx-paraformer-zh-small，源自阿里达摩院 Paraformer 中文 ASR）。
#
# 用法:
#   ./scripts/fetch-paraformer-zh-small.ps1
#
# 输出:
#   utils-support-models-onnx-paraformer-zh-small/src/main/resources/audio/asr/paraformer-zh-small/
#     ├── model.int8.onnx    (约 81MB，LFS)
#     ├── tokens.txt         (词表，8359 个 token)
#     └── configuration.json
#
# 模型元数据（已固化在 ONNX 内，供运行时使用）:
#   lfr_window_size=7, lfr_window_shift=6, vocab_size=8359,
#   neg_mean/inv_stddev (80 维 CMVN), model_type=paraformer

[CmdletBinding()]
param(
    [string]$BaseUrl = "https://modelscope.cn/models/pengzhendong/sherpa-onnx-paraformer-zh-small/resolve/master"
)

$ErrorActionPreference = "Stop"
$destDir = Join-Path $PSScriptRoot "..\utils-support-models-onnx-paraformer-zh-small\src\main\resources\audio\asr\paraformer-zh-small"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

$files = @("model.int8.onnx", "tokens.txt", "configuration.json")

foreach ($f in $files) {
    $url = "$BaseUrl/$f"
    $out = Join-Path $destDir $f
    if (Test-Path $out) {
        Write-Host "==> 已存在，跳过: $f" -ForegroundColor Yellow
        continue
    }
    Write-Host "==> 下载 $f" -ForegroundColor Green
    Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -TimeoutSec 1800
    Write-Host "    <= $f ($([math]::Round((Get-Item $out).Length/1MB))MB)"
}

Write-Host ""
Write-Host "==> 后续步骤:" -ForegroundColor Green
Write-Host "  1. cd utils-support-models-parent"
Write-Host "  2. mvn install -pl utils-support-models-onnx-paraformer-zh-small -am -DskipTests"
Write-Host "  3. onnx-starter 侧通过 com.chua:utils-support-models-onnx-paraformer-zh-small 依赖引用"

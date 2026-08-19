#!/usr/bin/env pwsh
# 获取 utils-support-models-onnx-vits-icefall-zh 模块的 ONNX 模型文件
# （liaowenbin/vits-icefall-zh-aishell3，sherpa-onnx 导出，源自 icefall AISHELL3 中文 TTS）。
#
# 用法:
#   ./scripts/fetch-vits-icefall-zh.ps1
#
# 输出:
#   utils-support-models-onnx-vits-icefall-zh/src/main/resources/audio/tts/vits-icefall-zh/
#     ├── model.onnx    (约 30MB)
#     ├── tokens.txt    (音素词表，219 个 token，sil=0/eos=1)
#     ├── speakers.txt  (174 个 AISHELL3 说话人)
#     └── lexicon.txt   (字 → 音素映射，66k 汉字)
#
# 模型元数据（已固化在 ONNX 内，供运行时使用）:
#   model_type=vits, language=Chinese, n_speakers=174, sample_rate=8000
#
# 运行时输入（sherpa-onnx 标准 VITS）:
#   tokens(1,T) int64, tokens_lens(1,) int64, noise_scale/alpha/noise_scale_dur(1,) float32,
#   speaker(1,) int64 → 输出 audio(1,N) float32 @8kHz

[CmdletBinding()]
param(
    [string]$BaseUrl = "https://modelscope.cn/api/v1/models/liaowenbin/vits-icefall-zh-aishell3/repo?Revision=master&FilePath="
)

$ErrorActionPreference = "Stop"
$destDir = Join-Path $PSScriptRoot "..\utils-support-models-onnx-vits-icefall-zh\src\main\resources\audio\tts\vits-icefall-zh"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

$files = @("model.onnx", "tokens.txt", "speakers.txt", "lexicon.txt")

foreach ($f in $files) {
    $url = "$BaseUrl$f"
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
Write-Host "  2. mvn install -pl utils-support-models-onnx-vits-icefall-zh -am -DskipTests"
Write-Host "  3. onnx-starter 侧通过 com.chua:utils-support-models-onnx-vits-icefall-zh 依赖引用"
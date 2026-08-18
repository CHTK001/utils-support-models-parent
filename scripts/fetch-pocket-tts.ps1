#!/usr/bin/env pwsh
# 获取 utils-support-models-onnx-pocket-tts 模块的 ONNX 模型文件（Kyutai Pocket-TTS int8 导出）。
#
# 用法:
#   ./scripts/fetch-pocket-tts.ps1
#   ./scripts/fetch-pocket-tts.ps1 -Url "<模型包 tar.bz2 直链>"
#
# 输出:
#   utils-support-models-onnx-pocket-tts/src/main/resources/audio/tts/pocket-tts/
#     ├── text_encoder.onnx
#     ├── flow.onnx
#     ├── mimi_decoder.onnx
#     └── tokenizer.json
#
# 默认源: sherpa-onnx Pocket-TTS int8 模型包（HuggingFace csukuangfj2，需科学上网）。
# 备选源: KevinAHM/pocket-tts-onnx（HuggingFace，导出脚本见 KevinAHM/pocket-tts-onnx-export）。
#
# 注意: 若实际导出的 ONNX 文件名/张量名与默认不同，请修改
#   src/main/resources/audio/tts/pocket-tts/config.json 中的 model_files / tensor_names。

[CmdletBinding()]
param(
    [string]$Url
)

$ErrorActionPreference = "Stop"
$destDir = Join-Path $PSScriptRoot "..\utils-support-models-onnx-pocket-tts\src\main\resources\audio\tts\pocket-tts"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

if (-not $Url) {
    $Url = "https://huggingface.co/csukuangfj2/sherpa-onnx-pocket-tts-int8-2026-01-26/resolve/main/sherpa-onnx-pocket-tts-int8-2026-01-26.tar.bz2"
    Write-Warning "使用默认源: $Url"
    Write-Warning "文件约 225MB，下载时间取决于网络。若 GitHub/HF 直连失败，请手动下载后指定 -Url 指向本地文件。"
}

Write-Host "==> 下载 Pocket-TTS int8 ONNX 模型包" -ForegroundColor Green
Write-Host "    Source: $Url"
Write-Host "    Target: $destDir"

$tmp = Join-Path $env:TEMP "pocket-tts.tar.bz2"
$extractDir = Join-Path $env:TEMP "pocket-tts-extract"

try {
    if ($Url -like "file://*" -or (Test-Path $Url -ErrorAction SilentlyContinue)) {
        Copy-Item $Url $tmp
    } else {
        Invoke-WebRequest -Uri $Url -OutFile $tmp -UseBasicParsing -TimeoutSec 1800
    }
    if ((Get-Item $tmp).Length -lt 10MB) {
        Write-Warning "文件小于 10MB，可能下载失败或非模型包。请检查 URL。"
    }

    if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
    tar -xjf $tmp -C $extractDir

    $onnx = Get-ChildItem -Path $extractDir -Recurse -Filter "*.onnx"
    if (-not $onnx) {
        throw "未在包中找到 .onnx 文件，请检查包内容或改用 -Url 指定正确导出。"
    }
    foreach ($f in $onnx) {
        Copy-Item $f.FullName (Join-Path $destDir $f.Name) -Force
        Write-Host "    <= $($f.Name) ($([math]::Round($f.Length/1MB))MB)"
    }

    # tokenizer: 优先 tokenizer.json；其次 bpe.model / sp.model（sentencepiece，需先转换）
    $tok = Get-ChildItem -Path $extractDir -Recurse -Include "tokenizer.json","bpe.model","sp.model","vocab.txt" | Select-Object -First 1
    if ($tok) {
        Copy-Item $tok.FullName (Join-Path $destDir $tok.Name) -Force
        Write-Host "    <= $($tok.Name)"
        if ($tok.Name -ne "tokenizer.json") {
            Write-Warning "模型包提供的是 $($tok.Name) 而非 tokenizer.json，请转换为 HuggingFace tokenizer.json 后放入目标目录。"
        }
    } else {
        Write-Warning "未在包中找到 tokenizer 文件，请手动下载 tokenizer.json 放入目标目录。"
    }
} catch {
    Write-Host "==> 下载/解压失败: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "备选方案:" -ForegroundColor Yellow
    Write-Host "  1. 手动下载 (浏览器/Curl) 后放入: $destDir"
    Write-Host "  2. 使用 KevinAHM/pocket-tts-onnx (HuggingFace) 的导出文件"
    Write-Host "  3. 用 KevinAHM/pocket-tts-onnx-export 脚本自行导出"
    exit 1
}

Write-Host ""
Write-Host "==> 后续步骤:" -ForegroundColor Green
Write-Host "  1. 核对 config.json 中的 model_files / tensor_names 与实际文件一致"
Write-Host "  2. cd utils-support-models-parent"
Write-Host "  3. mvn install -pl utils-support-models-onnx-pocket-tts -am -DskipTests"
Write-Host ""

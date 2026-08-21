# Fetch Pocket-TTS int8 ONNX model files (csukuangfj2/sherpa-onnx-pocket-tts-int8)
# Usage: ./scripts/fetch-pocket-tts.ps1
# Output: utils-support-models-onnx-pocket-tts/src/main/resources/audio/tts/pocket-tts/
#   - lm_main.int8.onnx        (text_encoder, ~76MB)
#   - lm_flow.int8.onnx        (flow, ~10MB)
#   - decoder.int8.onnx        (mimi_decoder, ~22MB)
#   - encoder.onnx             (mimi_encoder, ~73MB, voice cloning)
#   - vocab.json               (tokenizer)

[CmdletBinding()]
param(
    [string]$BaseUrl = "https://huggingface.co/csukuangfj2/sherpa-onnx-pocket-tts-int8-2026-01-26/resolve/main"
)

$ErrorActionPreference = "Stop"
$destDir = Join-Path $PSScriptRoot "..\utils-support-models-onnx-pocket-tts\src\main\resources\audio\tts\pocket-tts"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

$files = @("lm_main.int8.onnx", "lm_flow.int8.onnx", "decoder.int8.onnx", "encoder.onnx", "vocab.json")

Write-Host "==> Downloading Pocket-TTS int8 ONNX models" -ForegroundColor Green
Write-Host "    BaseUrl: $BaseUrl"
Write-Host "    Target:  $destDir"
Write-Host ""

$success = 0
$failed  = @()

foreach ($file in $files) {
    $url = "$BaseUrl/$file"
    $out = Join-Path $destDir $file

    if (Test-Path $out) {
        $sizeMB = [math]::Round((Get-Item $out).Length / 1MB, 1)
        Write-Host "  [skip] $file  (${sizeMB}MB, exists)" -ForegroundColor Yellow
        $success++
        continue
    }

    Write-Host "  [download] $file" -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -TimeoutSec 600
        $sizeMB = [math]::Round((Get-Item $out).Length / 1MB, 1)
        if ($sizeMB -lt 0.05) {
            Write-Host "    WARNING: file too small (${sizeMB}MB), download may have failed" -ForegroundColor Red
            Remove-Item $out -Force -ErrorAction SilentlyContinue
            $failed += $file
        } else {
            Write-Host "    <= $file (${sizeMB}MB)" -ForegroundColor Green
            $success++
        }
    } catch {
        Write-Host "    FAIL: $file - $($_.Exception.Message)" -ForegroundColor Red
        $failed += $file
    }
}

Write-Host ""

if ($failed.Count -gt 0) {
    Write-Host "==> FAILED files, please check network or download manually:" -ForegroundColor Red
    foreach ($f in $failed) { Write-Host "    - $f" -ForegroundColor Red }
    Write-Host "    Target dir: $destDir" -ForegroundColor Red
    exit 1
}

$totalMB = [math]::Round((Get-ChildItem $destDir -File | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
Write-Host "==> Done! Total: ${totalMB}MB" -ForegroundColor Green
Write-Host "==> Next steps:" -ForegroundColor Green
Write-Host "  1. cd utils-support-models-parent"
Write-Host "  2. mvn install -pl utils-support-models-onnx-pocket-tts -am -DskipTests"
Write-Host "  3. Voice cloning: .voice('ref.wav') passes reference audio path"
Write-Host ""

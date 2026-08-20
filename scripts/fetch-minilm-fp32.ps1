#!/usr/bin/env pwsh
<#
.SYNOPSIS
    下载 all-MiniLM-L6-v2 未量化版（fp32）模型到 utils-support-models-onnx-minilm-fp32 模块。

.DESCRIPTION
    从 HuggingFace 下载 Xenova/all-MiniLM-L6-v2 的未量化 ONNX 模型（model.onnx, ~90MB）
    和 vocab.txt，放置到 src/main/resources/nlp/embedding/minilm-fp32/ 目录。

    如果 HuggingFace 被 hosts 文件屏蔽，自动尝试 hf-mirror.com 镜像。

.NOTES
    需要 PowerShell 5.1+ 或 pwsh 7+
#>

$ErrorActionPreference = 'Stop'

$TARGET_DIR = Join-Path $PSScriptRoot '..\utils-support-models-onnx-minilm-fp32\src\main\resources\nlp\embedding\minilm-fp32'
$TARGET_DIR = [System.IO.Path]::GetFullPath($TARGET_DIR)

# 确保目标目录存在
New-Item -ItemType Directory -Force -Path $TARGET_DIR | Out-Null

# 文件列表：model.onnx (fp32, ~90MB) + vocab.txt
$FILES = @(
    @{ Name = 'model.onnx';      Url = 'https://huggingface.co/Xenova/all-MiniLM-L6-v2/resolve/main/onnx/model.onnx' }
    @{ Name = 'vocab.txt';       Url = 'https://huggingface.co/Xenova/all-MiniLM-L6-v2/resolve/main/vocab.txt' }
)

# 镜像地址
$MIRROR_FILES = @(
    @{ Name = 'model.onnx';      Url = 'https://hf-mirror.com/Xenova/all-MiniLM-L6-v2/resolve/main/onnx/model.onnx' }
    @{ Name = 'vocab.txt';       Url = 'https://hf-mirror.com/Xenova/all-MiniLM-L6-v2/resolve/main/vocab.txt' }
)

function Download-File {
    param(
        [string]$Url,
        [string]$OutFile,
        [int]$MaxRetries = 2
    )

    for ($i = 0; $i -le $MaxRetries; $i++) {
        try {
            Write-Host "  下载: $Url"
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add('User-Agent', 'Mozilla/5.0')
            $wc.DownloadFile($Url, $OutFile)
            $size = (Get-Item $OutFile).Length
            Write-Host "  完成: $OutFile ($([math]::Round($size / 1MB, 1)) MB)"
            return $true
        } catch {
            Write-Host "  失败: $($_.Exception.Message)" -ForegroundColor Yellow
            if ($i -lt $MaxRetries) {
                Write-Host "  重试 ($($i+1)/$MaxRetries)..."
                Start-Sleep -Seconds 2
            }
        }
    }
    return $false
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " all-MiniLM-L6-v2 fp32 未量化版下载器" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "目标目录: $TARGET_DIR"
Write-Host ""

$success = 0
$total = $FILES.Count

foreach ($file in $FILES) {
    $outPath = Join-Path $TARGET_DIR $file.Name

    if (Test-Path $outPath) {
        $existingSize = (Get-Item $outPath).Length
        Write-Host "[跳过] $($file.Name) 已存在 ($([math]::Round($existingSize / 1MB, 1)) MB)" -ForegroundColor Green
        $success++
        continue
    }

    Write-Host "[下载] $($file.Name)..."

    # 先尝试 HuggingFace
    $ok = Download-File -Url $file.Url -OutFile $outPath
    if (-not $ok) {
        # 尝试镜像
        $mirrorFile = $MIRROR_FILES | Where-Object { $_.Name -eq $file.Name } | Select-Object -First 1
        if ($mirrorFile) {
            Write-Host "  HuggingFace 失败，尝试 hf-mirror.com..."
            $ok = Download-File -Url $mirrorFile.Url -OutFile $outPath
        }
    }

    if ($ok) { $success++ }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 结果: $success / $total 文件下载成功" -ForegroundColor $(if ($success -eq $total) { 'Green' } else { 'Yellow' })

if ($success -eq $total) {
    Write-Host ""
    Write-Host "所有文件已下载到: $TARGET_DIR" -ForegroundColor Green
    Write-Host "可以运行 mvn compile 打包为 utils-support-models-onnx-minilm-fp32.jar" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "部分文件下载失败，请手动从 HuggingFace 下载:" -ForegroundColor Yellow
    Write-Host "  https://huggingface.co/Xenova/all-MiniLM-L6-v2/tree/main/onnx" -ForegroundColor Yellow
}

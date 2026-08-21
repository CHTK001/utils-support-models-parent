#!/usr/bin/env pwsh
# ============================================================================
# onnxruntime-gpu 一键环境准备脚本（Windows / Linux 自动适配）
#
# 自动完成:
#   1. 探测 OS 平台 (Windows / Linux)
#   2. 探测 GPU 驱动 CUDA 主版本 (nvidia-smi)
#   3. 自动选择匹配的 pip 运行时包 (nvidia-*-cu<XX>) —— pip 自动下对应平台 DLL/.so
#   4. 安装到隔离 venv，然后拷贝 libcudart/libcublas/libcudnn 到目标目录
#
# 适用: onnxruntime-gpu + DJL/OpenCV 用到 GPU 推理的场景
# 前提: NVIDIA 驱动已装（nvidia-smi 可用），无需完整 CUDA Toolkit / cuDNN 账号
#
# 用法:
#   ./setup-onnx-gpu.ps1                        # 自动探测 + 默认 CUDA 12
#   ./setup-onnx-gpu.ps1 -TargetDir D:\libs\cuda
#   ./setup-onnx-gpu.ps1 -CudaMajor 11          # 强制 CUDA 11 (cudnn8)
#   ./setup-onnx-gpu.ps1 -CudaMajor 13
#   ./setup-onnx-gpu.ps1 -DryRun                # 预览
#   ./setup-onnx-gpu.ps1 -OrtVersion 1.21.1     # 目标 onnxruntime-gpu 版本（校验层）
# ============================================================================

[CmdletBinding()]
param(
    [string]$TargetDir,
    [ValidateSet("11", "12", "13")]
    [string]$CudaMajor,
    [ValidateSet("1.16.3", "1.17.1", "1.18.1", "1.19.2", "1.20.1", "1.21.1", "1.22.0", "1.23.2", "1.25.1")]
    [string]$OrtVersion = "1.23.2",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$pkgRoot = Split-Path -Parent $PSScriptRoot
if (-not $TargetDir) {
    $TargetDir = Join-Path $pkgRoot "libs\cuda"
}
New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

$IsWin = $env:OS -like "*Windows*"
$libExt = if ($IsWin) { "dll" } else { "so" }

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " onnxruntime-gpu CUDA 运行库一键准备 ($(if($IsWin){'Windows'}else{'Linux'}))" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# ---------- 1. 探测 NVIDIA 驱动 ----------
$gpu = $null
try { $gpu = (nvidia-smi 2>&1 | Select-String -Pattern 'NVIDIA-SMI') } catch { }
if (-not $gpu) {
    Write-Host "!! 未检测到 NVIDIA 驱动。请先安装驱动:" -ForegroundColor Red
    Write-Host "   https://www.nvidia.com/drivers"
    Write-Host "   参考 CUDA 驱动版本表: https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/#cuda-major-component-versions"
    exit 1
}
$smiLine = $gpu.Line
$driVer  = if ($smiLine -match 'Driver Version:\s*([\d.]+)') { $Matches[1] } else { "?" }
$cuVer   = if ($smiLine -match 'CUDA Version:\s*([\d.]+)') { $Matches[1] } else { "?" }
Write-Host ("  驱动版本  : {0}" -f $driVer)
Write-Host ("  驱动CUDA  : {0}" -f $cuVer)

# ---------- 2. 自动选 CUDA 主版本 ----------
if (-not $CudaMajor) {
    if ($cuVer -match '^(\d+)') {
        $CudaMajor = $Matches[1]
        if ($CudaMajor -notin @("11", "12", "13")) {
            Write-Host ("  CUDA {0} 映射到 CUDA 12 方案" -f $CudaMajor) -ForegroundColor Yellow
            $CudaMajor = "12"
        }
    } else {
        $CudaMajor = "12"
    }
}

# ---------- 3. onnxruntime-gpu 配置匹配校验（信息性） ----------
Write-Host ""
Write-Host "==> 方案: CUDA $CudaMajor" -ForegroundColor Green
$ortMap = @{
    "1.16.3" = "11"; "1.17.1" = "11"; "1.18.1" = "11"
    "1.19.2" = "12"; "1.20.1" = "12"; "1.21.1" = "12"
    "1.22.0" = "12"; "1.23.2" = "12"; "1.25.1" = "12"
}
$recommendedOrts = ($ortMap.GetEnumerator() | Where-Object { $_.Value -eq $CudaMajor } | ForEach-Object { $_.Key })
Write-Host "  目标 onnxruntime-gpu 版本: $OrtVersion"
Write-Host ("  CUDA {0} 推荐 ort-gpu 版本: {1}" -f $CudaMajor, ($recommendedOrts -join ", "))
$mapCuda = $ortMap[$OrtVersion]
if ($mapCuda -and $mapCuda -ne $CudaMajor) {
    Write-Host ("  !! 警告: ort-gpu $OrtVersion 偏 CUDA $mapCuda，但你选了 CUDA $CudaMajor") -ForegroundColor Yellow
}

# ---------- 4. 选 pip 包 ----------
$runtimePkg = "nvidia-cuda-runtime-cu$CudaMajor"
$cublasPkg  = "nvidia-cublas-cu$CudaMajor"
$cudnnPkg   = "nvidia-cudnn-cu$CudaMajor"
Write-Host ("  安装包    : {0}, {1}, {2}" -f $runtimePkg, $cublasPkg, $cudnnPkg)

if ($DryRun) {
    Write-Host ""
    Write-Host "==> DryRun 结束（未安装）。目标目录: $TargetDir" -ForegroundColor Yellow
    exit 0
}

# ---------- 5. 隔离 venv 安装 nvidia 运行时包 ----------
$tmpVenv = Join-Path $pkgRoot "target\cuda-venv"
if (-not (Test-Path (Join-Path $tmpVenv "Scripts\python.exe")) -and -not (Test-Path (Join-Path $tmpVenv "bin\python"))) {
    python -m venv $tmpVenv 2>$null
}
if ($IsWin) {
    $pip = Join-Path $tmpVenv "Scripts\pip.exe"
    $siteBase = Join-Path $tmpVenv "Lib\site-packages"
} else {
    $pip = Join-Path $tmpVenv "bin\pip"
    $siteBase = Join-Path $tmpVenv "lib\python*\site-packages"
}
if (-not (Test-Path $pip)) { $pip = "pip" }

foreach ($pkg in @($runtimePkg, $cublasPkg, $cudnnPkg)) {
    Write-Host "==> 安装 $pkg ..."
    & $pip install --quiet --disable-pip-version-check $pkg 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    $pkg 安装失败，重试（可能网络/镜像）..." -ForegroundColor Yellow
        & $pip install --quiet --disable-pip-version-check --retries 3 $pkg 2>&1 | Out-Null
    }
}

# ---------- 6. 拷贝 DLL/.so 到目标目录 ----------
Write-Host ""
Write-Host "==> 拷贝 $libExt 到 $TargetDir" -ForegroundColor Green
$copied = 0
$sitePkgs = if ($IsWin) {
    Get-ChildItem $siteBase -Directory -ErrorAction SilentlyContinue
} else {
    Get-ChildItem (Join-Path $tmpVenv "lib") -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Get-ChildItem (Join-Path $_.FullName "site-packages") -Directory -ErrorAction SilentlyContinue
    }
}
foreach ($sp in $sitePkgs) {
    Get-ChildItem $sp.FullName -Recurse -Include "*.$libExt" -File -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $TargetDir $_.Name) -Force -ErrorAction SilentlyContinue
        $copied++
    }
}

# ---------- 7. 校验 key 库 ----------
Write-Host ""
Write-Host "==> 结果: 已拷贝 $copied 个 $libExt 文件" -ForegroundColor Green
$cudart  = if ($IsWin) { "cudart64_$CudaMajor.dll" } else { "libcudart.so.$CudaMajor" }
$cublas  = if ($IsWin) { "cublas64_$CudaMajor.dll" } else { "libcublas.so.$CudaMajor" }
$cudnn   = if ($IsWin) { "cudnn64_9.dll" } else { "libcudnn.so.9" }
$checks  = @(
    @{ Name = "cudart ($cudart)"; File = $cudart }
    @{ Name = "cublas ($cublas)"; File = $cublas }
    @{ Name = "cudnn  ($cudnn)";  File = $cudnn }
)
foreach ($c in $checks) {
    $ok = Test-Path (Join-Path $TargetDir $c.File)
    # 兜底：Linux 常是 libcudnn.so.9 带 symlink 变体
    if (-not $ok -and -not $IsWin) {
        $ok = (Get-ChildItem $TargetDir -Filter "*cudnn*.so*" -ErrorAction SilentlyContinue) -ne $null
    }
    Write-Host ("  {0,-34} {1}" -f $c.Name, $(if ($ok) { "OK" } else { "MISSING!" }))
}

Write-Host ""
Write-Host "==> 后续步骤:" -ForegroundColor Green
Write-Host "  1. onnx-starter pom 将 onnxruntime 换成 onnxruntime-gpu:$OrtVersion"
Write-Host "  2. 启动 JVM 加: -Djava.library.path=$TargetDir"
Write-Host "  3. Java 用 SessionOptions.addCUDA() 打开 CUDA EP"
Write-Host "  4. Windows 注意: onnxruntime-gpu 需 MSVC 运行库 (vc_redist.x64.exe)"
Write-Host ""
Write-Host "Linux 追加提示: 确保 ldconfig 认识目标目录或设置 LD_LIBRARY_PATH=$TargetDir" -ForegroundColor Yellow
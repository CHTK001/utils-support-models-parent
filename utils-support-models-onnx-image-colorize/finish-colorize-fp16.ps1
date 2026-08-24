# finish-colorize-fp16.ps1
# 用 121MB fp16 权重替换 833MB fp32，重装模型 jar 并跑通上色推理。
# 前提：系统可用内存 ≥ 5GB（建议先关闭其他重型会话/构建）。
$ErrorActionPreference = 'Stop'

$moduleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$dst = Join-Path $moduleDir 'src\main\resources\vision\colorization\deoldify\model.onnx'
$url = 'https://github.com/instant-high/deoldify-onnx/releases/download/deoldify-onnx/deoldify_fp16.onnx'

# 0) 内存门槛
$os = Get-CimInstance Win32_OperatingSystem
$freeGB = [math]::Round($os.FreeVirtualMemory / 1MB, 1)
if ($freeGB -lt 5) {
    Write-Host "[ABORT] 可用提交内存仅 ${freeGB}GB (<5GB)。请先释放内存（如关闭并行构建会话）。"
    exit 1
}
Write-Host "[1/4] 可用提交内存 ${freeGB}GB，开始..."

# 1) 下载 fp16 权重
Remove-Item $dst -Force -ErrorAction SilentlyContinue
curl.exe -sL --retry 3 --retry-delay 3 -o $dst $url
if (-not (Test-Path $dst) -or (Get-Item $dst).Length -lt 50MB) {
    Write-Host "[ABORT] 下载失败或文件过小"
    exit 1
}
Write-Host ("[2/4] fp16 权重就绪: " + [math]::Round((Get-Item $dst).Length / 1MB, 1) + " MB")

# 2) 重装模型 jar
Push-Location $moduleDir
mvn -o install -DskipTests
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Host "[ABORT] 模型 jar 安装失败"; exit 1 }
Pop-Location
Write-Host "[3/4] 模型 jar 已更新"

# 3) 跑真实上色推理（argfile 由主仓 example-starter 会话生成；若缺失则提示）
$argfile = Join-Path $env:TEMP 'color-inf.args'
if (-not (Test-Path $argfile)) {
    Write-Host "[WARN] 未找到 $argfile ，请让主仓会话重新生成后再运行本脚本第3步"
    exit 0
}
java "@$argfile"
Write-Host ("[4/4] 推理退出码: " + $LASTEXITCODE)
exit $LASTEXITCODE

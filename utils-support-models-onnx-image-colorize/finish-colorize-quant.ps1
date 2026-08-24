# finish-colorize-quant.ps1
# 将已嵌入的 fp32(833MB) DeOldify 动态量化为 int8（体积/加载内存降约 70%），
# 重装模型 jar 并跑通真实上色推理。全程离线。
#
# 前提：可用提交内存 ≥ 4GB（onnx.load 需要大块内存）。
#       建议先关闭其他重型会话/构建再运行。

$ErrorActionPreference = 'Stop'

$moduleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$weights   = Join-Path $moduleDir 'src\main\resources\vision\colorization\deoldify\model.onnx'
$quantOut  = Join-Path $moduleDir 'src\main\resources\vision\colorization\deoldify\model_int8.onnx'

# 0) 内存门槛
$os = Get-CimInstance Win32_OperatingSystem
$freeGB = [math]::Round($os.FreeVirtualMemory / 1MB, 1)
if ($freeGB -lt 4) {
    Write-Host "[ABORT] 可用提交内存仅 ${freeGB}GB (<4GB)。请先关闭其他重型会话/构建。"
    exit 1
}
Write-Host "[1/5] 可用提交内存 ${freeGB}GB"

# 1) 动态量化 fp32 -> int8
if (-not (Test-Path $weights)) {
    Write-Host "[ABORT] 找不到 fp32 权重: $weights"
    exit 1
}
Write-Host "[2/5] 量化中（833MB，需数分钟）..."
python -c "from onnxruntime.quantization import quantize_dynamic, QuantType; quantize_dynamic(r'$weights', r'$quantOut', weight_type=QuantType.QUInt8)"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $quantOut)) {
    Write-Host "[ABORT] 量化失败"
    exit 1
}
$qsize = [math]::Round((Get-Item $quantOut).Length / 1MB, 1)
Write-Host ("      量化完成: {0} MB" -f $qsize)

# 2) 用 int8 替换默认权重
Move-Item $quantOut $weights -Force
Write-Host "[3/5] 已替换 model.onnx"

# 3) 重装模型 jar
Push-Location $moduleDir
mvn -o install -DskipTests
$ok = ($LASTEXITCODE -eq 0)
Pop-Location
if (-not $ok) { Write-Host "[ABORT] 模型 jar 安装失败"; exit 1 }
Write-Host "[4/5] 模型 jar 已更新"

# 4) 跑真实上色推理
$argfile = Join-Path $env:TEMP 'color-inf.args'
if (-not (Test-Path $argfile)) {
    Write-Host "[WARN] 未找到 $argfile（由主仓 example-starter 会话生成）。模型已就绪，推理验证请稍后手动执行。"
    exit 0
}
java "@$argfile"
Write-Host ("[5/5] 推理退出码: " + $LASTEXITCODE)
exit $LASTEXITCODE

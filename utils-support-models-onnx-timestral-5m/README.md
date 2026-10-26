# Timestral-5M ONNX 模型资源模块

Mistral Timestral-5M 单变量时间序列预测模型（fp32，~21.2MB）。

## 模型规格

| 参数 | 值 |
|------|----|
| 上下文长度 | 512 步（16 patch × 32） |
| 预测 horizon | 32 步 |
| 输出分位数 | 21 档（0.01…0.99） |
| 模型大小 | ~21.2 MB（fp32） |

## 文件结构

```
src/main/resources/timeseries/timestral/timestral-5m/
├── model.onnx      # 模型权重（~21.2MB）
├── config.json     # 模型配置（patch_size, quantile_knots, use_asinh 等）
└── LICENSE         # Mistral AI 开源协议
```

## model.onnx 状态

`model.onnx`、`config.json` 与 `LICENSE` 已于 2026-10-24 从
`onnx-community/Timestral-5M-ONNX`（HuggingFace）下载并嵌入本模块资源目录：

- `model.onnx` — 21,212,151 字节（21.2 MB，fp32，ONNX IR v8）
- `config.json` — 904 字节（patch_size=32, quantile_knots 21 档, use_asinh=true）
- `LICENSE` — Mistral AI 开源协议（mistral-modified-mit）

下载来源：
`https://huggingface.co/onnx-community/Timestral-5M-ONNX/resolve/main/`

### 重新下载方式

如需重新获取或更新模型文件，可执行：

```powershell
# 国际站（huggingface.co）
curl -L -o model.onnx "https://huggingface.co/onnx-community/Timestral-5M-ONNX/resolve/main/onnx/model.onnx"

# 国内镜像（hf-mirror.com，需网络可达）
curl -L -o model.onnx "https://hf-mirror.com/onnx-community/Timestral-5M-ONNX/resolve/main/onnx/model.onnx"
```

下载完成后将文件放入本目录：
`src/main/resources/timeseries/timestral/timestral-5m/model.onnx`

### 运行时自动下载

`OnnxModelRegistrar` 已注册 downloadUrl，`ModelRegistry` 在运行时若找不到 jar 内嵌资源，
会尝试从以下 URL 自动下载：

1. `https://hf-mirror.com/onnx-community/Timestral-5M-ONNX/resolve/main/onnx/model.onnx`
2. `https://huggingface.co/onnx-community/Timestral-5M-ONNX/resolve/main/onnx/model.onnx`

## 编译

```powershell
Push-Location .\utils-support-models-onnx-timestral-5m
mvn clean compile -q
Pop-Location
```

## 使用

通过 `TimeSeriesForecaster` 能力接口调用：

```java
TimeSeriesForecaster forecaster = ModelRegistry.get("timestral-5m");
// 或使用通用接口
ForecastResult result = forecaster.forecast(
    new ForecastRequest(context, 32, new double[]{0.1, 0.5, 0.9})
);
double[] point = result.point();          // 32 步点预测（0.5 分位）
double[][] intervals = result.forecast(); // 各目标分位数的 32 步预测
```

> **注意**：模型 horizon 固定为 32 步。若请求的 `horizon` 参数小于 32，结果将被截断；
> 大于 32 时会抛出 `IllegalArgumentException`。

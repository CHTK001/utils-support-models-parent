# utils-support-models-pytorch-wevisdoc-layout

WeVisDoc 版面检测模型（pytorch / 远程 HTTP）。

## 模型信息

| 属性 | 值 |
|---|---|
| 模型 ID（本地） | `wevisdoc-layout` |
| 模型 ID（远程） | `wevisdoc-layout-remote` |
| 能力接口 | `ImageDetector`（→ `LayoutDetector`） |
| 输入 | `Image` |
| 输出 | `DetectedObjects`（11 类版面块） |
| 标签 | text, paragraph_title, table, figure, figure_caption, table_caption, list, header, footer, reference, equation |
| 原始权重 | Qwen3-VL-2B（4.8GB FP32 safetensors） |
| 本地格式 | torchscript `.pt`（待转换） |
| 远程格式 | HTTP JSON（Python 服务返回 Markdown） |

## 两种模式

### 本地模式 `wevisdoc-layout`

使用 `WevisdocTranslator` + torchscript 权重。DJL pytorch 引擎直接加载。

**状态**：骨架完成，待权重转换（Qwen3-VL-2B → torchscript）。

### 远程模式 `wevisdoc-layout-remote`

使用 `WevisdocRemoteTranslator` + Python HTTP 服务。无需本地权重。

**状态**：代码完成，待模型下载后验证。

管线：Image → HTTP → Python 服务（Qwen3-VL-2B）→ Markdown → 解析 → DetectedObjects

## 消费方式

```java
// 远程模式（推荐，无需本地权重）
ImageDetector detector = ImageDetector.create("wevisdoc-layout-remote");

// 本地模式（待权重转换完成后）
ImageDetector detector = ImageDetector.create("wevisdoc-layout");

// 或通过 LayoutPipeline
LayoutPipeline pipeline = LayoutPipeline.builder()
        .model("wevisdoc-layout-remote")
        .build();

// 或查询可用模型
List<String> models = LayoutDetector.listModels();
```

## 组件

| 类 | 说明 | 测试 |
|---|---|---|
| `WevisdocTranslator` | 本地 torchscript 翻译器（ViT 预处理 + `[N,6]` 解析） | 6 |
| `WevisdocRemoteTranslator` | 远程 HTTP 翻译器（Markdown → 版面框） | 8 |
| `WevisdocHttpClient` | HTTP 客户端（调用 Python 服务） | 9 |
| `WevisdocMarkdownParser` | Markdown 元素解析（11 类映射） | 13 |
| `WevisdocLayoutBridge` | Markdown 元素 ↔ OCR 文字位置匹配 | 12 |
| `WevisdocLayoutSpiTest` | SPI 注册验证（本地 + 远程） | 4 |
| `WevisdocRemoteDemoTest` | 远程推理 Demo（4 基准页，需服务） | 1 |
| **总计** | | **53**（52 通过 + 1 跳过需服务） |

## Python 服务

启动 WeVisDoc HTTP 推理服务：

```bash
python wevisdoc_service.py
# 默认端口 8765
# GET  /status  → 模型状态
# POST /infer   → 图片推理（返回 Markdown）
```

## 验收脚本

下载完成后一键验收：

```bash
# Python 端到端验收（7 基准页推理 + Markdown 结构统计）
python wevisdoc_acceptance.py

# Java 端远程推理 Demo（4 基准页）
# mvn test -Dtest=WevisdocRemoteDemoTest

# Java 单元测试全套
# mvn test -Dtest=Wevisdoc*Test
```

## 脚本列表

| 脚本 | 说明 |
|---|---|
| `wevisdoc_service.py` | HTTP 推理服务（端口 8765） |
| `wevisdoc_probe.py` | Step1 探针（7 页推理 + 结构统计） |
| `wevisdoc_acceptance.py` | 端到端验收（模型加载 + 推理 + 报告） |
| `download_model.py` | 并行下载脚本（4 线程分块） |

## 当前状态

### 已完成
- `WevisdocTranslator`（本地 torchscript 翻译器）
- `WevisdocRemoteTranslator`（远程 HTTP 翻译器）
- `WevisdocHttpClient`（HTTP 客户端）
- `WevisdocMarkdownParser`（Markdown 元素解析）
- `WevisdocLayoutBridge`（Markdown ↔ OCR 匹配）
- `PytorchModelRegistrar` 注册 `wevisdoc-layout` + `wevisdoc-layout-remote`
- 单元测试 52/52 通过
- Python HTTP 推理服务脚本

### 待完成
1. **模型下载**：4.8GB safetensors（进行中，16.1%）
2. **Python 推理验证**：下载完成后运行 `wevisdoc_acceptance.py`
3. **权重转换**：Qwen3-VL-2B → torchscript（提取视觉编码器 + 检测头）
4. **集成测试**：加入 `LayoutModelBenchmarkTest` 横向对比

## LICENSE

WeVisDoc 权重遵循 Tencent/WeVisDoc 仓库的 LICENSE（见原始仓库）。

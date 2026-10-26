# utils-support-models-onnx-indra-layout

datalab-to/indra 文档版面分析 ONNX 模型族（内嵌 jar，离线可用）。

## 来源

- 上游仓库：<https://github.com/datalab-to/indra>（Apache-2.0）
- 权重仓库：<https://huggingface.co/datalab-to/indra-ocr>（revision `v1.1.0`）

## 内容（`src/main/resources/vision/layout/indra/`）

| 文件 | 体积 | 说明 |
|---|---|---|
| `det.onnx` | ~0.39 MB | LineNet：灰度页 → 行墨迹框 |
| `rec.onnx` | ~5.0 MB | CTC 识别器（基础/拉丁）：行裁剪 → 文本（含 CTC 解码头） |
| `order.onnx` | ~3.0 MB | OrderNet：行特征 → 10 类块分类 / 同块 / 阅读顺序 / 表格头 logit |
| `script.onnx` | ~0.19 MB | 语种分类器：行为 base / cjk / rtl / world 哪一族 |
| `rec_cjk.onnx` | ~10.2 MB | 中日韩识别器（`vocab_cjk`，11749 字符） |
| `meta.json` | ~0.21 MB | 词表（`vocab`/`vocab_cjk`…）、`det_long_side`、`rec_window`、`script_groups` |
| `config.json` | 703 B | 上游配置 |
| `LICENSE` | — | Apache License 2.0 |

> 可选分组识别器：把 `rec_rtl.onnx`（阿拉伯/希伯来等，`vocab_rtl`）或
> `rec_world.onnx`（天城文/泰文等，`vocab_world`）放进本目录即可启用，
> 无需改代码 —— 装载器按 `meta.json` 的 `vocab_<分组>` 键自动发现。
> 未内嵌是为了控制 jar 体积（各约 5 MB）。

## 消费方式

在 `utils-support-deeplearning-onnx-starter` 中由 `IndraLayoutTranslator` 装载，
注册标识 `indra-layout`，可用于：

```java
// 版面块（标签 + 外接框）
List<DetectionInfo> blocks = ImageDetector.create("indra-layout").detect(pngBytes);

// 或经布局管线
Object r = LayoutPipeline.builder().model("indra-layout").build().recognizeSingle(pngBytes);
```

块标签（chandra）：`Text` / `Section-Header` / `Page-Header` / `Page-Footer` /
`List-Group` / `Table` / `Caption` / `Footnote` / `Table-Of-Contents` / `Form`。

## 实测精度（7 张合成真值页 / 37 块，IoU≥0.5）

| 指标 | 本模型 | 同批次对照 |
|---|---|---|
| 块 F1（IoU≥0.5） | 0.960 | doc-layout-yolo 0.987（最高）、pp-doc-layout-l 0.875 |
| 标签正确率 | 0.917 | pp-doc-layout(V3) 0.969（最高） |
| 单页耗时 | 658 ms | 其余 5 个模型 1387~4550 ms |
| 块内文字 CER（4249 字符） | 1.2% | 其它版面模型不产文字，无从对比 |

分页最弱项是含图片的页面（F1 0.73）：`det.onnx` 输出只有 3 个通道（core logit +
行上下边界距离），没有上游代码里预留的 picture 通道，因此本模型**不产出 Figure/图片块**，
上游用同一份权重也一样。完整对照表见
`utils-support-deeplearning-onnx-starter/模型测试报告.md` §15.1。

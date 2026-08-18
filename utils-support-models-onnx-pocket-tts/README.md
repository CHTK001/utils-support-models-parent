# utils-support-models-onnx-pocket-tts

Kyutai **Pocket-TTS**（100M 参数流匹配 TTS）嵌入式 ONNX 模型包。

- 模型来源：sherpa-onnx Pocket-TTS int8 导出（`csukuangfj2/sherpa-onnx-pocket-tts-int8-2026-01-26`）或 KevinAHM/pocket-tts-onnx
- 采样率：**24kHz**
- 组件：`text_encoder.onnx`（文本编码）+ `flow.onnx`（流匹配 LM）+ `mimi_decoder.onnx`（Mimi 解码器）+ `tokenizer.json`
- 体积：约 **225MB**（int8 量化），推理内存 ~400-700MB，纯 CPU 可超实时

## 获取模型文件

模型文件体积大（~225MB），不直接入库，需执行下载脚本：

```powershell
cd utils-support-models-parent
./scripts/fetch-pocket-tts.ps1
```

脚本将模型包下载并解压到 `src/main/resources/audio/tts/pocket-tts/`。
若实际导出的 ONNX 文件名 / 张量名与默认不同，请修改同目录 `config.json` 中的
`model_files` / `tensor_names`（默认按 sherpa-onnx 导出约定填写）。

## 构建

```bash
mvn install -pl utils-support-models-onnx-pocket-tts -am -DskipTests
```

## 说明

- 模型加载 / 流匹配采样循环由 `utils-support-deeplearning-onnx-starter` 的
  `PocketTtsTranslator` 实现（配置驱动，兼容不同导出包的张量名差异）。
- 使用方式：`TextToAudioClient.create("onnx", "").model("pocket-tts").synthesize("...")`。

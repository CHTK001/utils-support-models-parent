# utils-support-models-onnx-pocket-tts

Kyutai **Pocket-TTS**（100M 参数流匹配 TTS）嵌入式 ONNX 模型包。

- 模型来源：sherpa-onnx Pocket-TTS int8 导出（`csukuangfj2/sherpa-onnx-pocket-tts-int8-2026-01-26`）
- 采样率：**24kHz**
- 组件：`lm_main.int8.onnx`（text_encoder）+ `lm_flow.int8.onnx`（flow）+ `decoder.int8.onnx`（mimi_decoder）+ `encoder.onnx`（mimi_encoder，声音克隆）+ `vocab.json`（tokenizer）
- 体积：约 **173MB**（int8 量化），推理内存 ~500MB，纯 CPU 可超实时

## 文件说明

| 文件 | 大小 | 用途 |
|------|------|------|
| `lm_main.int8.onnx` | ~73MB | text_encoder，文本编码为潜变量 |
| `lm_flow.int8.onnx` | ~10MB | flow，流匹配一致性采样模型 |
| `decoder.int8.onnx` | ~22MB | mimi_decoder，潜变量→波形 |
| `encoder.onnx` | ~69MB | mimi_encoder，参考音频→说话人潜变量（声音克隆必需） |
| `vocab.json` | ~70KB | BPE tokenizer 词表 |
| `config.json` | — | 推理配置（tensor_names / 超参数） |

## 声音克隆

mimi_encoder（`encoder.onnx`）启用零样本声音克隆：

```java
TextToAudioClient.create("onnx", "")
    .model("pocket-tts")
    .voice("reference.wav")   // wav 文件路径，自动作为音色参考
    .synthesize("Hello world");
```

参考音频要求：
- 格式：16-bit PCM WAV（其他格式自动重采样到 24kHz 单声道）
- 时长：建议 3~10 秒，越长越稳定
- 内容：清晰语音，无背景噪音

## 构建

模型文件已内嵌在 `src/main/resources/audio/tts/pocket-tts/` 下，直接构建即可：

```bash
cd utils-support-models-parent
mvn install -pl utils-support-models-onnx-pocket-tts -am -DskipTests
```

若需重新下载：
```powershell
cd utils-support-models-parent
./scripts/fetch-pocket-tts.ps1
mvn install -pl utils-support-models-onnx-pocket-tts -am -DskipTests
```

## 使用

```java
// 默认音色合成
byte[] wav = TextToAudioClient.create("onnx", "")
    .model("pocket-tts")
    .synthesize("Hello world");

// 声音克隆
byte[] clonedWav = TextToAudioClient.create("onnx", "")
    .model("pocket-tts")
    .voice("my_voice_reference.wav")
    .synthesize("Speaking in cloned voice");
```

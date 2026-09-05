# utils-support-models-onnx-ueba

UEBA（用户实体行为分析）ONNX 模型仓库。

## 目录结构

```
utils-support-models-onnx-ueba/
├── pom.xml
└── src/main/resources/ueba/
    ├── README.md                       ← 本文件
    ├── autoencoder_ip.onnx             ← IP 异常流量检测（AutoEncoder）— 训练后放入
    ├── lstm_attention_behavior.onnx    ← 行为序列分类（GRU + Attention）— 训练后放入
    ├── checkpoint/                     ← 训练时自动生成（用于续训）
    │   ├── autoencoder_ip_latest.pt
    │   └── lstm_attention_behavior_latest.pt
    ├── train_ueba.py                   ← 训练脚本（与 ueba-starter 内置同源）
    └── ueba-config.example.yaml        ← 训练/推理配置示例
```

## 模型契约（Java 端翻译器强依赖）

| 模型文件 | 输入 | 输出 | 训练时导出参数 |
|---|---|---|---|
| `autoencoder_ip.onnx` | `features: float[1, N]` | `reconstruction: float[1, N]` | `input_names=["features"], output_names=["reconstruction"]` |
| `lstm_attention_behavior.onnx` | `sequence_ids: int64[1, L]` + `sequence_numeric: float32[1, L, M]` | `logits: float[1, K]` | `input_names=["sequence_ids", "sequence_numeric"], output_names=["logits"]` |

`N` = `ueba-config.yaml` 中 `features` 配置数量；`L` = `lstm.windowSize`；`M` = `lstm.numNumericFeatures`（默认 4）；`K` = `lstm.numClasses`（默认 3）。

## 训练（从零）

### A. Java 链式训练

```java
Ueba.training()
     .configResource("ueba-config.yaml")
     .data(Path.of("access.csv"))          // 或 .events(eventsList)
     .outputDir(Path.of("target/ueba-models"))
     .epochs(50)
     .batchSize(64)
     .learningRate(1e-3)
     .build()
     .execute();
```

执行后将产出：
- `target/ueba-models/autoencoder_ip.onnx`
- `target/ueba-models/lstm_attention_behavior.onnx`
- `target/ueba-models/ueba-config-derived.yaml`（回写 scaler / vocab / threshold）
- `target/ueba-models/checkpoint/*.pt`（用于续训）
- `target/ueba-models/train_ueba.py`（脚本副本）

依赖：Python 3.9+、`pip install torch numpy pyyaml`（脚本内置在 `utils-support-ueba-starter` 资源 `python/train_ueba.py`）。

### B. Python 直接训练

```bash
python train_ueba.py \
    --config ueba-config.example.yaml \
    --data access.csv \
    --output ./models \
    --epochs 50 --batch-size 64 --learning-rate 0.001
```

CSV 列：`timestamp,ip,path,method,status,user_agent,response_time,response_size`

## 训练（基于已有模型续训 / 微调）

支持 checkpoint 续训。再次执行训练时通过 `--resume` 指向已有模型目录，训练脚本会自动从 `checkpoint/<stem>_latest.pt` 加载权重并继续训练：

```java
// Java 链式
Ueba.training()
     .configResource("ueba-config.yaml")
     .data(newCsv)
     .outputDir(Path.of("target/ueba-models-v2"))
     .resume(Path.of("target/ueba-models"))     // ← 续训来源
     .epochs(30)
     .build()
     .execute();
```

```bash
# Python
python train_ueba.py \
    --config ueba-config.example.yaml \
    --data new_access.csv \
    --output ./models-v2 \
    --resume ./models \
    --epochs 30
```

## 放置到本仓库（发布 jar）

将训练产出的 `autoencoder_ip.onnx` 与 `lstm_attention_behavior.onnx` 拷贝到
`src/main/resources/ueba/`（覆盖 README 中的占位说明），然后执行：

```bash
mvn install -pl utils-support-models-onnx-ueba -am
```

发布后，使用方在 `utils-support-ueba-starter`（或 `spring-support-ueba-starter`）的
`pom.xml` 引入本模块即可自动从 classpath 加载模型：

```xml
<dependency>
    <groupId>com.chua</groupId>
    <artifactId>utils-support-models-onnx-ueba</artifactId>
    <version>4.0.0.42</version>
</dependency>
```

## 推理（Java）

```java
// 链式门面
UebaEngine engine = Ueba.engine()
        .configResource("ueba-config.yaml")
        .modelDir(Path.of("/path/to/trained"))      // 优先级 2
        // 或 .configPath(...) 走优先级 1
        // 走 classpath 加载时无需 modelDir（依赖 utils-support-models-onnx-ueba 即可）
        .disableLlm()
        .build();

UebaResult result = engine.analyze(trafficEvent);
```

模型加载优先级：

1. 配置文件 `autoEncoder.modelPath` / `lstm.modelPath` 显式指定
2. `-Dueba.model.dir` 或构建器 `.modelDir(dir)`
3. classpath `models/ueba/`（本仓库产物）

## 回写配置说明

训练脚本同时会回写 `preprocessing.scalers`（min-max / z-score 参数）和
`preprocessing.vocab`（path→id 映射）到 `ueba-config-derived.yaml`。将 `derived` 拷贝回
`ueba-config.yaml` 才能让 Java 端使用与训练一致的归一化参数与词表，否则推理结果会异常。

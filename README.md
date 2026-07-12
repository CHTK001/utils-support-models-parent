# utils-support-models-parent

预编译 ONNX 模型库聚合项目。模型以 jar 形式发布到 GitHub Packages，通过 SPI 机制与应用层解耦。

## 模块

| 模块 | 大小 | 说明 | 来源 |
|---|---|---|---|
| `utils-support-models-onnx-whisper` | 27MB | Whisper-tiny ASR 语音识别 | HuggingFace |
| `utils-support-models-onnx-paddleocrv6-tiny` | 6MB | PP-OCRv6 轻量 OCR（检测+识别） | ModelScope |
| `utils-support-models-onnx-paddleocrv6-medium` | 96MB | PP-OCRv6 高精度 OCR（检测+识别） | ModelScope |
| `utils-support-models-onnx-retinaface` | 104MB | RetinaFace R50 人脸检测 | HuggingFace |
| `utils-support-models-onnx-yolov5-plate` | 4.5MB | YOLOv5 车牌检测+识别+颜色 | ModelScope |
| `utils-support-models-onnx-card-correction` | 39MB | 读光卡证检测矫正 | ModelScope |

## 使用方式

### Maven

```xml
<repositories>
    <repository>
        <id>github</id>
        <url>https://maven.pkg.github.com/CHTK001/utils-support-models-parent</url>
    </repository>
</repositories>

<!-- 按需引入 -->
<dependency>
    <groupId>com.chua</groupId>
    <artifactId>utils-support-models-onnx-whisper</artifactId>
    <version>4.0.0.41</version>
</dependency>
```

### Gradle

```kotlin
repositories {
    maven {
        url = uri("https://maven.pkg.github.com/CHTK001/utils-support-models-parent")
    }
}

dependencies {
    implementation("com.chua:utils-support-models-onnx-whisper:4.0.0.41")
}
```

## 模型下载

部分大文件 ONNX（`*.onnx` > 100MB）不提交到 Git，需运行下载脚本后打包进 jar：

```bash
# 下载所有模型的 ONNX 文件
python utils-support-models-onnx-whisper/download_whisper_tiny.py
python utils-support-models-onnx-retinaface/download_retinaface.py

# 打包进 jar
mvn clean install
```

运行时通过 `ModelDownloadProvider` SPI 自动从 jar 中提取模型文件到缓存目录，无需手动配置。

## 构建

```bash
mvn clean install -DskipModelDownload  # 跳过模型下载
mvn clean install                       # 自动下载并打包
```

## 发布

```bash
mvn deploy -DskipModelDownload
```

目标仓库：`https://maven.pkg.github.com/CHTK001/utils-support-models-parent`

## 新增模型

在 `utils-support-deeplearning-onnx-starter` 的 `OnnxModelDownloadProvider` 中添加下载清单，
并在 `OnnxIdentificationEngine` 中注册模型名称即可对接现有推理引擎。

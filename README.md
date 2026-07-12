# utils-support-models-parent

预编译 ONNX 模型库聚合项目。模型以 jar 形式发布到 GitHub Packages，通过 SPI 机制与应用层解耦。

## 模块

| 模块 | 说明 |
|---|---|
| `utils-support-models-onnx-whisper` | Xenova/whisper-tiny ASR 语音识别模型（BPE 词表 + mel 滤波器 + 下载配置） |

## 使用方式

### Maven

```xml
<repositories>
    <repository>
        <id>github</id>
        <url>https://maven.pkg.github.com/CHTK001/utils-support-models-parent</url>
    </repository>
</repositories>

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

ONNX 大文件（`*.onnx`）不提交到 Git，需要运行下载脚本：

```bash
pip install huggingface-hub
python utils-support-models-onnx-whisper/download_whisper_tiny.py
```

或通过应用的 `ModelDownloadProvider` SPI 自动下载。

## 构建

```bash
mvn clean install
```

## 发布

```bash
mvn deploy
```

目标仓库：`https://maven.pkg.github.com/CHTK001/utils-support-models-parent`

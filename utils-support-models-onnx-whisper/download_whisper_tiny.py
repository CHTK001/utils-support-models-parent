#!/usr/bin/env python3
"""下载 Whisper-tiny ONNX 模型文件到模块资源目录，用于打包进 jar。"""

import os
import sys
from pathlib import Path

try:
    from huggingface_hub import hf_hub_download
except ImportError:
    print("请先安装 huggingface-hub: pip install huggingface-hub")
    sys.exit(1)

REPO_ID = "Xenova/whisper-tiny"
FILES = [
    "onnx/encoder_model_quantized.onnx",
    "onnx/decoder_model_merged_quantized.onnx",
    "vocab.json",
    "mel_80_filters.json",
    "byte_decoder.json",
    "config.json",
    "tokenizer_config.json",
]

# 优先读取环境变量 HF_ENDPOINT，默认使用 Hugging Face 镜像
HF_ENDPOINT = os.environ.get("HF_ENDPOINT", "https://hf-mirror.com")

# 目标目录：模块资源目录，ONNX 文件将被打包进 jar
target = Path(__file__).resolve().parent / "src" / "main" / "resources" / "audio" / "asr" / "whisper-tiny"


def main() -> None:
    target.mkdir(parents=True, exist_ok=True)
    for file in FILES:
        dest = target / file
        if dest.exists():
            print(f"[跳过] 已存在: {dest}")
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        print(f"[下载] {file} ...")
        hf_hub_download(REPO_ID, filename=file, local_dir=target, endpoint=HF_ENDPOINT)
        print(f"[完成] {dest}")
    print(f"\n所有模型文件已下载到: {target}")
    print("运行 mvn clean install 即可将模型打包进 jar。")


if __name__ == "__main__":
    main()

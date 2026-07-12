#!/usr/bin/env python3
"""下载 Whisper-tiny ONNX 模型文件到本地模型缓存。"""

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

# 目标目录：可指定 MODEL_CACHE 环境变量，默认当前目录
target = Path(os.environ.get("MODEL_CACHE", Path.cwd() / "models" / "audio" / "asr" / "whisper-tiny"))


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


if __name__ == "__main__":
    main()

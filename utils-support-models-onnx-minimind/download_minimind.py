#!/usr/bin/env python3
"""MiniMind Omni ONNX 模型下载脚本

从 HuggingFace 或镜像站下载 MiniMind Omni 的 ONNX 模型文件。
下载路径:
  - tokenizer.json          -> src/main/resources/models/minimind/tokenizer.json
  - tokenizer_config.json   -> src/main/resources/models/minimind/tokenizer_config.json
  - minimind_omni_prefill.onnx  -> src/main/resources/models/minimind/
  - minimind_omni_decode.onnx   -> src/main/resources/models/minimind/
"""

import os
import sys
import urllib.request
import json

MODELS_PARENT = os.path.dirname(os.path.abspath(__file__))
RESOURCE_DIR = os.path.join(MODELS_PARENT, "src", "main", "resources", "models", "minimind")

# 模型文件列表和下载地址（替换为实际的模型存储地址）
MODEL_FILES = {
    # 分词器配置
    "tokenizer.json": "https://huggingface.co/YanTianlong-01/MiniMind-Omni/resolve/main/tokenizer.json",
    "tokenizer_config.json": "https://huggingface.co/YanTianlong-01/MiniMind-Omni/resolve/main/tokenizer_config.json",
    # 核心推理模型
    "minimind_omni_prefill.onnx": "https://huggingface.co/YanTianlong-01/MiniMind-Omni/resolve/main/onnx/minimind_omni_prefill.onnx",
    "minimind_omni_decode.onnx": "https://huggingface.co/YanTianlong-01/MiniMind-Omni/resolve/main/onnx/minimind_omni_decode.onnx",
    # 语音处理模型
    "audio_projector.onnx": "https://huggingface.co/YanTianlong-01/MiniMind-Omni/resolve/main/onnx/audio_projector.onnx",
    "silero_vad.onnx": "https://huggingface.co/YanTianlong-01/MiniMind-Omni/resolve/main/onnx/silero_vad.onnx",
    "sensevoice_cmvn.json": "https://huggingface.co/YanTianlong-01/MiniMind-Omni/resolve/main/sensevoice_cmvn.json",
}


def download_file(url, dest):
    """下载文件并显示进度"""
    print(f"Downloading {os.path.basename(dest)} ...")
    try:
        urllib.request.urlretrieve(url, dest)
        size = os.path.getsize(dest)
        print(f"  OK ({size / 1024 / 1024:.1f} MB)")
        return True
    except Exception as e:
        print(f"  FAILED: {e}")
        return False


def main():
    os.makedirs(RESOURCE_DIR, exist_ok=True)

    # 尝试从 HuggingFace 镜像站下载，若失败则从原始地址下载
    mirrors = [
        "https://hf-mirror.com",  # HF 国内镜像
    ]
    success = 0
    failed = 0

    for filename, url in MODEL_FILES.items():
        dest = os.path.join(RESOURCE_DIR, filename)

        # 如果文件已存在且不是 onnx 文件，跳过下载
        if os.path.exists(dest) and not filename.endswith(".onnx"):
            print(f"Skipping {filename} (already exists)")
            success += 1
            continue

        # 尝试原始地址下载
        if download_file(url, dest):
            success += 1
        else:
            # 尝试镜像地址
            downloaded = False
            for mirror in mirrors:
                mirror_url = url.replace("https://huggingface.co", mirror)
                if download_file(mirror_url, dest):
                    downloaded = True
                    success += 1
                    break
            if not downloaded:
                print(f"  All sources failed for {filename}")
                failed += 1

    print(f"\nDownload complete: {success} success, {failed} failed")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())

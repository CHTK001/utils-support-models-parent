#!/usr/bin/env python3
"""下载 PP-OCRv6 ONNX 模型文件到模块资源目录，用于打包进 jar。"""

import os
import sys
import urllib.request
from pathlib import Path

try:
    from huggingface_hub import hf_hub_download
except ImportError:
    print("请先安装 huggingface-hub: pip install huggingface-hub")
    sys.exit(1)

# Tiny 检测模型（~9.9MB）
DET_REPO = "PaddlePaddle/PP-OCRv6_small_det_onnx"
# Tiny 识别模型（~21MB）
REC_REPO = "PaddlePaddle/PP-OCRv6_small_rec_onnx"

FILES = [
    (DET_REPO, "inference.onnx", "ocr/PP-OCRv6/tiny/det_infer/inference.onnx"),
    (DET_REPO, "inference.json", "ocr/PP-OCRv6/tiny/det_infer/inference.json"),
    (DET_REPO, "inference.yml", "ocr/PP-OCRv6/tiny/det_infer/inference.yml"),
    (REC_REPO, "inference.onnx", "ocr/PP-OCRv6/tiny/rec_infer/inference.onnx"),
    (REC_REPO, "inference.json", "ocr/PP-OCRv6/tiny/rec_infer/inference.json"),
    (REC_REPO, "inference.yml", "ocr/PP-OCRv6/tiny/rec_infer/inference.yml"),
    # 词表文件（来自 PaddleOCR GitHub）
    ("", "https://gitee.com/paddlepaddle/PaddleOCR/raw/main/ppocr/utils/ppocr_keys_v1.txt",
     "ocr/PP-OCRv6/tiny/rec_infer/dict.txt"),
]

HF_ENDPOINT = os.environ.get("HF_ENDPOINT", "https://hf-mirror.com")
target = Path(__file__).resolve().parent / "src" / "main" / "resources"


def main() -> None:
    for entry in FILES:
        repo_id, src_file, dest_rel = entry
        dest = target / dest_rel
        if dest.exists():
            print(f"[跳过] 已存在: {dest}")
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        if not repo_id:
            print(f"[下载] {src_file} -> {dest_rel} ...")
            try:
                req = urllib.request.Request(src_file, headers={"User-Agent": "Mozilla/5.0"})
                resp = urllib.request.urlopen(req, timeout=30)
                content = resp.read()
                with open(dest, "wb") as f:
                    f.write(content)
                print(f"[完成] {dest} ({len(content)} bytes)")
            except Exception as e:
                print(f"[失败] {src_file}: {e}")
                sys.exit(1)
        else:
            print(f"[下载] {repo_id}/{src_file} -> {dest_rel} ...")
            hf_hub_download(repo_id, filename=src_file, local_dir=dest.parent, endpoint=HF_ENDPOINT)
            print(f"[完成] {dest}")
    print(f"\n所有模型文件已下载到: {target}")
    print("运行 mvn clean install 即可将模型打包进 jar。")


if __name__ == "__main__":
    main()

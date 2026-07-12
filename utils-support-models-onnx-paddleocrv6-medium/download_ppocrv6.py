#!/usr/bin/env python3
"""下载 PP-OCRv6 Medium ONNX 模型文件（从 ModelScope）到模块资源目录。"""

import os
import sys
import urllib.request
from pathlib import Path

MODELSCOPE = "https://www.modelscope.cn/models"

FILES = [
    # Medium 检测模型（~62MB）
    (f"{MODELSCOPE}/PaddlePaddle/PP-OCRv6_medium_det_onnx/resolve/master/inference.onnx",
     "ocr/PP-OCRv6/medium/det_infer/inference.onnx"),
    (f"{MODELSCOPE}/PaddlePaddle/PP-OCRv6_medium_det_onnx/resolve/master/inference.json",
     "ocr/PP-OCRv6/medium/det_infer/inference.json"),
    (f"{MODELSCOPE}/PaddlePaddle/PP-OCRv6_medium_det_onnx/resolve/master/inference.yml",
     "ocr/PP-OCRv6/medium/det_infer/inference.yml"),
    # Medium 识别模型（~77MB）
    (f"{MODELSCOPE}/PaddlePaddle/PP-OCRv6_medium_rec_onnx/resolve/master/inference.onnx",
     "ocr/PP-OCRv6/medium/rec_infer/inference.onnx"),
    (f"{MODELSCOPE}/PaddlePaddle/PP-OCRv6_medium_rec_onnx/resolve/master/inference.json",
     "ocr/PP-OCRv6/medium/rec_infer/inference.json"),
    (f"{MODELSCOPE}/PaddlePaddle/PP-OCRv6_medium_rec_onnx/resolve/master/inference.yml",
     "ocr/PP-OCRv6/medium/rec_infer/inference.yml"),
    # 词表文件
    ("https://gitee.com/paddlepaddle/PaddleOCR/raw/main/ppocr/utils/ppocr_keys_v1.txt",
     "ocr/PP-OCRv6/medium/rec_infer/dict.txt"),
]

target = Path(__file__).resolve().parent / "src" / "main" / "resources"


def main() -> None:
    for url, dest_rel in FILES:
        dest = target / dest_rel
        if dest.exists():
            print(f"[跳过] 已存在: {dest}")
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        print(f"[下载] {dest_rel} ...")
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            resp = urllib.request.urlopen(req, timeout=300)
            content = resp.read()
            with open(dest, "wb") as f:
                f.write(content)
            print(f"[完成] {dest} ({len(content)} bytes)")
        except Exception as e:
            print(f"[失败] {url}: {e}")
            sys.exit(1)
    print(f"\n所有模型文件已下载到: {target}")
    print("运行 mvn clean install 即可将模型打包进 jar。")


if __name__ == "__main__":
    main()

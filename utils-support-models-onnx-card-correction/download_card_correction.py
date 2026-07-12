#!/usr/bin/env python3
"""下载卡证检测矫正 ONNX 模型文件到模块资源目录。"""

import sys
import urllib.request
from pathlib import Path

MODELSCOPE = "https://www.modelscope.cn/models"

FILES = [
    ("card_detection.onnx", "cv/card_correction/card_detection.onnx"),
]

target = Path(__file__).resolve().parent / "src" / "main" / "resources"


def main() -> None:
    for fname, dest_rel in FILES:
        dest = target / dest_rel
        if dest.exists():
            print(f"[跳过] 已存在: {dest}")
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        url = f"{MODELSCOPE}/JinzhangLi/cv_resnet18_card_correction_onnx/resolve/master/{fname}"
        print(f"[下载] {fname} ...")
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            resp = urllib.request.urlopen(req, timeout=120)
            content = resp.read()
            with open(dest, "wb") as f:
                f.write(content)
            print(f"[完成] {dest} ({len(content)} bytes)")
        except Exception as e:
            print(f"[失败] 用 modelscope SDK 下载...")
            try:
                from modelscope.hub.snapshot_download import snapshot_download
                model_dir = snapshot_download('JinzhangLi/cv_resnet18_card_correction_onnx',
                    cache_dir=str(target.parent.parent / ".mscache"))
                import shutil, os
                src = os.path.join(model_dir, fname)
                if os.path.exists(src):
                    shutil.copy2(src, str(dest))
                    print(f"[完成] {dest} ({os.path.getsize(dest)} bytes)")
                else:
                    print(f"[错误] 文件 {fname} 不在下载目录中")
                    sys.exit(1)
            except Exception as e2:
                print(f"[失败] SDK 也失败: {e2}")
                sys.exit(1)
    print(f"\n所有模型文件已下载到: {target}")


if __name__ == "__main__":
    main()

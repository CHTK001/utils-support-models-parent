#!/usr/bin/env python3
"""下载 YOLOv5 车牌检测 ONNX 模型文件到模块资源目录。"""

import sys
import urllib.request
from pathlib import Path

MODELSCOPE = "https://www.modelscope.cn/models"

FILES = [
    ("yolov5_plate_detect.onnx",  "vision/detection/yolov5_plate/yolov5_plate_detect.onnx"),
    ("yolov5_plate_rec_color.onnx", "vision/detection/yolov5_plate/yolov5_plate_rec_color.onnx"),
    ("yolov5_car_plate.yaml",      "vision/detection/yolov5_plate/yolov5_car_plate.yaml"),
    ("configuration.json",         "vision/detection/yolov5_plate/configuration.json"),
]

target = Path(__file__).resolve().parent / "src" / "main" / "resources"


def main() -> None:
    for fname, dest_rel in FILES:
        dest = target / dest_rel
        if dest.exists():
            print(f"[跳过] 已存在: {dest}")
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        url = f"{MODELSCOPE}/CVHub520/yolov5_car_plate/resolve/master/{fname}"
        print(f"[下载] {fname} ...")
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            resp = urllib.request.urlopen(req, timeout=60)
            content = resp.read()
            with open(dest, "wb") as f:
                f.write(content)
            print(f"[完成] {dest} ({len(content)} bytes)")
        except Exception as e:
            print(f"[失败] {fname}: {e}")
            sys.exit(1)
    print(f"\n所有模型文件已下载到: {target}")


if __name__ == "__main__":
    main()

"""
并行下载：4 线程分块下载到 D: 盘，各写独立临时文件，完成后合并。
"""
import sys
import os
import time
import ssl
import threading
import urllib.request
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

sys.stdout.reconfigure(encoding="utf-8")

URL = "https://huggingface.co/tencent/WeVisDoc-2B/resolve/main/model.safetensors"
DEST_DIR = Path(r"D:\ch\project\wevisdoc_model")
NUM_WORKERS = 4

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

progress_lock = threading.Lock()


def get_total_size():
    req = urllib.request.Request(URL, method="HEAD", headers={"User-Agent": "Mozilla/5.0"})
    resp = urllib.request.urlopen(req, timeout=30, context=ctx)
    return int(resp.headers.get("Content-Length", 0))


def download_part(start, end, part_idx):
    """下载 [start, end] 范围到临时文件。"""
    part_size = end - start + 1
    downloaded = 0
    last_report = 0
    tmp_path = DEST_DIR / f"part_{part_idx}.tmp"

    while downloaded < part_size:
        pos = start + downloaded
        chunk_end = min(pos + 50 * 1024 * 1024 - 1, end)
        req = urllib.request.Request(
            URL,
            headers={
                "User-Agent": "Mozilla/5.0",
                "Range": f"bytes={pos}-{chunk_end}",
            },
        )
        try:
            resp = urllib.request.urlopen(req, timeout=60, context=ctx)
            with open(tmp_path, "ab") as f:
                while True:
                    chunk = resp.read(1024 * 1024)
                    if not chunk:
                        break
                    f.write(chunk)
                    downloaded += len(chunk)
                    if downloaded - last_report >= 50 * 1024 * 1024:
                        print(f"  [part{part_idx}] {start + downloaded / 1e6:.0f}MB / {end / 1e6:.0f}MB", flush=True)
                        last_report = downloaded
        except Exception as e:
            print(f"  [part{part_idx}] 中断: {e}，5秒后重试...")
            time.sleep(5)
            continue

    print(f"  [part{part_idx}] 完成: {downloaded / 1e6:.0f}MB", flush=True)


def main():
    DEST_DIR.mkdir(parents=True, exist_ok=True)
    total = get_total_size()
    print(f"总大小: {total / 1e9:.2f}GB")

    chunk_size = total // NUM_WORKERS
    ranges = []
    for i in range(NUM_WORKERS):
        start = i * chunk_size
        end = (total - 1) if i == NUM_WORKERS - 1 else (start + chunk_size - 1)
        ranges.append((start, end, i))

    # 清理旧临时文件
    for p in DEST_DIR.glob("part_*.tmp"):
        p.unlink()

    print(f"\n开始并行下载 ({NUM_WORKERS} 线程) -> {DEST_DIR}")
    t0 = time.time()

    with ThreadPoolExecutor(max_workers=NUM_WORKERS) as executor:
        futures = {executor.submit(download_part, s, e, i): i for i, (s, e, i) in enumerate(ranges)}
        for future in as_completed(futures):
            try:
                future.result()
            except Exception as e:
                print(f"线程 {futures[future]} 出错: {e}")

    elapsed = time.time() - t0

    # 合并临时文件
    final_path = DEST_DIR / "model.safetensors"
    with open(final_path, "wb") as out:
        for i in range(NUM_WORKERS):
            tmp_path = DEST_DIR / f"part_{i}.tmp"
            with open(tmp_path, "rb") as part:
                while True:
                    buf = part.read(1024 * 1024 * 10)
                    if not buf:
                        break
                    out.write(buf)
            tmp_path.unlink()

    actual = final_path.stat().st_size
    print(f"\n下载完成: {elapsed:.0f}s ({elapsed / 60:.1f}min)")
    print(f"文件大小: {actual / 1e6:.0f}MB / {total / 1e6:.0f}MB")
    if actual == total:
        print("验证通过！")
    else:
        print(f"警告: 大小不匹配 {actual} != {total}")

    # 同时复制小文件
    import shutil
    src_dir = Path(r"C:\Users\Administrator\AppData\Local\Temp\opencode\wevisdoc_model")
    for f in ["config.json", "tokenizer.json", "tokenizer_config.json", "vocab.json",
              "merges.txt", "generation_config.json", "preprocessor_config.json",
              "video_preprocessor_config.json", "chat_template.json"]:
        src = src_dir / f
        if src.exists() and src.stat().st_size > 0:
            shutil.copy2(src, DEST_DIR / f)
    print(f"小文件已复制到 {DEST_DIR}")


if __name__ == "__main__":
    main()

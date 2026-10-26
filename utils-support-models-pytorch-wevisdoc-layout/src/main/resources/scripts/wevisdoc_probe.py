"""
WeVisDoc Step1 探针：对 7 个基准页推理，解析 Markdown 结构，统计版面元素。

下载完成后运行：
  python wevisdoc_probe.py
"""
import sys
import os
import time
import json
import io
import ssl
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

MODEL_DIR = Path(r"C:\Users\Administrator\AppData\Local\Temp\opencode\wevisdoc_model")
BENCH_DIR = Path(r"D:\ch\project\utils-support-parent-starter\utils-support-deeplearning-parent\utils-support-deeplearning-onnx-starter\src\test\resources\layout-bench")

BENCH_PAGES = [
    "article.png",
    "columns.png",
    "dense.png",
    "figure.png",
    "list.png",
    "mixed.png",
    "table.png",
]

# Markdown 元素正则
import re

HEADER_RE = re.compile(r"^(#{1,6})\s+(.+)$", re.MULTILINE)
TABLE_ROW_RE = re.compile(r"^\s*\|.*\|\s*$", re.MULTILINE)
TABLE_SEP_RE = re.compile(r"^\s*\|[\s:|-]+\|\s*$", re.MULTILINE)
LIST_RE = re.compile(r"^\s*(?:[-*+]|\d+[.)]))\s+(.+)$", re.MULTILINE)
FIGURE_RE = re.compile(r"!\[([^\]]*)\]\([^)]+\)")
EQUATION_RE = re.compile(r"\$+[^$]+\$+")
HTML_TABLE_RE = re.compile(r"<table[^>]*>.*?</table>", re.DOTALL)
HTML_FIGCAP_RE = re.compile(r"<figcaption[^>]*>.*?</figcaption>", re.DOTALL)
HTML_TBLCAP_RE = re.compile(r"<caption[^>]*>.*?</caption>", re.DOTALL)


def parse_elements(md):
    """解析 Markdown 为版面元素。"""
    elements = []
    if not md:
        return elements

    lines = md.split("\n")
    for i, line in enumerate(lines):
        trimmed = line.strip()
        if not trimmed:
            continue

        # 标题
        m = HEADER_RE.match(trimmed)
        if m:
            elements.append(("paragraph_title", trimmed, i))
            continue

        # 表格行
        if trimmed.startswith("|") and trimmed.endswith("|"):
            elements.append(("table", trimmed, i))
            continue

        # 列表
        m = LIST_RE.match(trimmed)
        if m:
            elements.append(("list", trimmed, i))
            continue

        # 图片
        m = FIGURE_RE.search(trimmed)
        if m:
            elements.append(("figure", trimmed, i))
            continue

        # 公式
        if trimmed.startswith("$$") or trimmed.startswith("$"):
            elements.append(("equation", trimmed, i))
            continue

        # HTML 表格
        if HTML_TABLE_RE.search(trimmed):
            elements.append(("table", trimmed, i))
            continue

        # 普通文本
        elements.append(("text", trimmed, i))

    return elements


def main():
    # 检查模型文件
    safetensors = MODEL_DIR / "model.safetensors"
    if not safetensors.exists():
        print("错误: 模型文件未下载完成")
        return

    size_mb = safetensors.stat().st_size / 1e6
    print(f"模型大小: {size_mb:.0f}MB")

    # 加载模型
    print("\n[1/3] 加载模型...")
    t0 = time.time()
    import torch
    from transformers import Qwen3VLForConditionalGeneration, AutoProcessor
    from PIL import Image

    model = Qwen3VLForConditionalGeneration.from_pretrained(
        str(MODEL_DIR),
        torch_dtype=torch.float32,
        device_map="cpu",
    )
    processor = AutoProcessor.from_pretrained(str(MODEL_DIR))
    print(f"  加载完成: {time.time()-t0:.1f}s")

    # 推理
    print("\n[2/3] 推理 7 个基准页...")
    results = {}
    total_time = 0

    for page in BENCH_PAGES:
        image_path = BENCH_DIR / page
        if not image_path.exists():
            print(f"  跳过 {page}: 文件不存在")
            continue

        t0 = time.time()
        image = Image.open(str(image_path)).convert("RGB")

        prompt = "Parse the document image into structured Markdown with HTML tables and LaTeX formulas."
        messages = [{
            "role": "user",
            "content": [
                {"type": "image", "image": image},
                {"type": "text", "text": prompt},
            ],
        }]
        text = processor.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
        inputs = processor(text=text, images=[image], return_tensors="pt")

        with torch.no_grad():
            output_ids = model.generate(**inputs, max_new_tokens=4096, do_sample=False)

        trimmed = output_ids[:, inputs.input_ids.shape[1]:]
        result = processor.batch_decode(trimmed, skip_special_tokens=True, clean_up_tokenization_spaces=False)
        markdown = result[0]

        elapsed = time.time() - t0
        total_time += elapsed

        # 解析元素
        elements = parse_elements(markdown)
        from collections import Counter
        cat_counts = Counter(e[0] for e in elements)

        results[page] = {
            "markdown": markdown,
            "elements": len(elements),
            "categories": dict(cat_counts),
            "elapsed_s": round(elapsed, 1),
        }

        print(f"  {page}: {len(elements)} 元素, {dict(cat_counts)}, {elapsed:.1f}s")

    # 汇总
    print(f"\n[3/3] 汇总")
    print(f"总耗时: {total_time:.1f}s ({total_time/len(results):.1f}s/页)")
    print(f"\n{'='*60}")
    print("WeVisDoc Step1 探针结果")
    print(f"{'='*60}")

    for page, r in results.items():
        print(f"\n--- {page} ---")
        print(f"  元素数: {r['elements']}")
        print(f"  类别: {r['categories']}")
        print(f"  耗时: {r['elapsed_s']}s")
        # 显示前 500 字符 Markdown
        md_preview = r['markdown'][:500]
        print(f"  Markdown (前500字符):")
        for line in md_preview.split('\n'):
            print(f"    {line}")

    # 保存完整结果
    out_path = Path(r"C:\Users\Administrator\AppData\Local\Temp\opencode\wevisdoc_probe_results.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    print(f"\n完整结果已保存: {out_path}")


if __name__ == "__main__":
    main()

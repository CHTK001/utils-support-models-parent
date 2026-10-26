"""
WeVisDoc 端到端验收脚本。

下载完成后运行：
  python wevisdoc_acceptance.py

步骤：
1. 检查模型文件完整性
2. 加载模型 + 推理 7 基准页
3. 解析 Markdown 结构
4. 输出验收报告
"""
import sys
import os
import time
import json
import io
import ssl
from pathlib import Path
from collections import Counter

sys.stdout.reconfigure(encoding="utf-8")

MODEL_DIR = Path(r"D:\ch\project\wevisdoc_model")
BENCH_DIR = Path(r"D:\ch\project\utils-support-parent-starter\utils-support-deeplearning-parent\utils-support-deeplearning-onnx-starter\src\test\resources\layout-bench")

BENCH_PAGES = [
    ("article.png", "文章页"),
    ("columns.png", "多栏页"),
    ("dense.png", "密集页"),
    ("figure.png", "图文页"),
    ("list.png", "列表页"),
    ("mixed.png", "混合页"),
    ("table.png", "表格页"),
]

# 11 类版面标签
LAYOUT_LABELS = [
    "text", "paragraph_title", "table", "figure",
    "figure_caption", "table_caption", "list",
    "header", "footer", "reference", "equation"
]

import re
HEADER_RE = re.compile(r"^(#{1,6})\s+(.+)$", re.MULTILINE)
TABLE_ROW_RE = re.compile(r"^\s*\|.*\|\s*$", re.MULTILINE)
LIST_RE = re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+(.+)$", re.MULTILINE)
FIGURE_RE = re.compile(r"!\[([^\]]*)\]\([^)]+\)")
EQUATION_RE = re.compile(r"\$+[^$]+\$+")
HTML_TABLE_RE = re.compile(r"<table[^>]*>.*?</table>", re.DOTALL)


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
        m = HEADER_RE.match(trimmed)
        if m:
            elements.append(("paragraph_title", trimmed)); continue
        if trimmed.startswith("|") and trimmed.endswith("|"):
            elements.append(("table", trimmed)); continue
        m = LIST_RE.match(trimmed)
        if m:
            elements.append(("list", trimmed)); continue
        m = FIGURE_RE.search(trimmed)
        if m:
            elements.append(("figure", trimmed)); continue
        if trimmed.startswith("$$") or trimmed.startswith("$"):
            elements.append(("equation", trimmed)); continue
        if HTML_TABLE_RE.search(trimmed):
            elements.append(("table", trimmed)); continue
        elements.append(("text", trimmed))
    return elements


def main():
    print("=" * 60)
    print("WeVisDoc 端到端验收")
    print("=" * 60)

    # 1. 检查模型
    safetensors = MODEL_DIR / "model.safetensors"
    if not safetensors.exists():
        print("❌ 模型文件不存在:", safetensors)
        return
    size_mb = safetensors.stat().st_size / 1e6
    print(f"\n[1/4] 模型文件: {size_mb:.0f}MB")

    # 检查小文件
    required = ["config.json", "tokenizer.json", "vocab.json", "merges.txt",
                "preprocessor_config.json", "generation_config.json"]
    missing = [f for f in required if not (MODEL_DIR / f).exists() or (MODEL_DIR / f).stat().st_size == 0]
    if missing:
        print(f"⚠️ 缺少小文件: {missing}")
    else:
        print(f"✅ 小文件完整 ({len(required)} 个)")

    # 2. 加载模型
    print(f"\n[2/4] 加载模型...")
    t0 = time.time()
    import torch
    from transformers import Qwen3VLForConditionalGeneration, AutoProcessor
    from PIL import Image

    model = Qwen3VLForConditionalGeneration.from_pretrained(
        str(MODEL_DIR), torch_dtype=torch.float32, device_map="cpu")
    processor = AutoProcessor.from_pretrained(str(MODEL_DIR))
    print(f"✅ 加载完成: {time.time()-t0:.1f}s")

    # 3. 推理
    print(f"\n[3/4] 推理 7 个基准页...")
    results = []
    total_time = 0

    for page, desc in BENCH_PAGES:
        image_path = BENCH_DIR / page
        if not image_path.exists():
            print(f"  ⚠️ 跳过 {page}: 文件不存在")
            continue

        t0 = time.time()
        image = Image.open(str(image_path)).convert("RGB")

        prompt = "Parse the document image into structured Markdown with HTML tables and LaTeX formulas."
        messages = [{"role": "user", "content": [
            {"type": "image", "image": image},
            {"type": "text", "text": prompt},
        ]}]
        text = processor.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
        inputs = processor(text=text, images=[image], return_tensors="pt")

        with torch.no_grad():
            output_ids = model.generate(**inputs, max_new_tokens=4096, do_sample=False)

        trimmed = output_ids[:, inputs.input_ids.shape[1]:]
        result = processor.batch_decode(trimmed, skip_special_tokens=True, clean_up_tokenization_spaces=False)
        markdown = result[0]

        elapsed = time.time() - t0
        total_time += elapsed

        elements = parse_elements(markdown)
        cat_counts = Counter(e[0] for e in elements)

        results.append({
            "page": page,
            "desc": desc,
            "markdown": markdown,
            "elements": len(elements),
            "categories": dict(cat_counts),
            "elapsed_s": round(elapsed, 1),
        })

        print(f"  {desc}({page}): {len(elements)} 元素, {dict(cat_counts)}, {elapsed:.1f}s")

    # 4. 验收报告
    print(f"\n[4/4] 验收报告")
    print("=" * 60)

    # 汇总统计
    total_elements = sum(r["elements"] for r in results)
    avg_elements = total_elements / len(results) if results else 0
    avg_time = total_time / len(results) if results else 0

    # 标签覆盖
    all_categories = Counter()
    for r in results:
        for k, v in r["categories"].items():
            all_categories[k] += v

    print(f"推理页数: {len(results)}")
    print(f"总元素数: {total_elements}")
    print(f"平均元素: {avg_elements:.1f} 个/页")
    print(f"平均耗时: {avg_time:.1f}s/页")
    print(f"总耗时: {total_time:.1f}s")
    print(f"\n版面标签覆盖:")
    for label in LAYOUT_LABELS:
        count = all_categories.get(label, 0)
        print(f"  {label:20s}: {count}")

    # Markdown 预览
    print(f"\nMarkdown 预览（article.png 前 800 字符）:")
    for r in results:
        if r["page"] == "article.png":
            print("-" * 40)
            for line in r["markdown"][:800].split("\n"):
                print(f"  {line}")
            break

    # 保存完整结果
    out_path = Path(r"D:\ch\project\wevisdoc_model\acceptance_results.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    print(f"\n完整结果: {out_path}")

    # 验收结论
    print(f"\n{'='*60}")
    if len(results) >= 7 and total_elements > 0:
        print("✅ 验收通过: 模型可加载，7 页推理成功，Markdown 结构可解析")
    else:
        print("❌ 验收未通过: 推理页数不足或元素数为 0")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()

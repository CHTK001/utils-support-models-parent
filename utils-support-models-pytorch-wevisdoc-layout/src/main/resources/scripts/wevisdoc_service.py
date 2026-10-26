"""
WeVisDoc HTTP 推理服务。

加载 Qwen3-VL-2B 模型，通过 HTTP 接收图片，返回 Markdown 文档解析结果。
使用 Python 内置 http.server，无需 Flask/FastAPI 依赖。

模型加载方式：Python mmap 手动解析 safetensors（避免 safe_open mmap 页面文件问题）。

接口：
  GET  /status  → 模型状态
  POST /infer   → 图片推理（raw PNG bytes）→ JSON {"markdown": "...", "elapsed_ms": 12345}

启动：
  python wevisdoc_service.py
  默认端口 8765
"""
import sys
import os
import json
import time
import mmap
import struct
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

import torch
torch.set_num_threads(12)

MODEL_DIR = Path(r"D:\ch\project\wevisdoc_model")
MODEL_PATH = MODEL_DIR / "model.safetensors"
PORT = 8765
MAX_NEW_TOKENS = 512

# 全局模型句柄
_model = None
_processor = None
_model_lock = threading.Lock()
_model_loading = False
_model_loaded = False

_dtype_map = {
    "F32": torch.float32,
    "F16": torch.float16,
    "BF16": torch.bfloat16,
    "I64": torch.int64,
    "I32": torch.int32,
    "I16": torch.int16,
    "I8": torch.int8,
    "U8": torch.uint8,
    "BOOL": torch.bool,
}


def load_model():
    """加载模型（Python mmap 手动解析 safetensors，避免页面文件问题）。"""
    global _model, _processor, _model_loading, _model_loaded

    if _model_loaded:
        return True
    if _model_loading:
        while _model_loading:
            time.sleep(0.5)
        return _model_loaded

    _model_loading = True
    try:
        from transformers import AutoConfig, Qwen3VLForConditionalGeneration, AutoProcessor

        print(f"[{time.strftime('%H:%M:%S')}] 加载 safetensors header...")
        with open(MODEL_PATH, "rb") as f:
            header_len = struct.unpack("<Q", f.read(8))[0]
            header = json.loads(f.read(header_len))

        print(f"[{time.strftime('%H:%M:%S')}] 构建模型 (BF16)...")
        old_dtype = torch.get_default_dtype()
        torch.set_default_dtype(torch.bfloat16)
        cfg = AutoConfig.from_pretrained(str(MODEL_DIR))
        model = Qwen3VLForConditionalGeneration(cfg)
        torch.set_default_dtype(old_dtype)
        model_sd = model.state_dict()

        print(f"[{time.strftime('%H:%M:%S')}] 加载 {len(header)-1} tensors (mmap)...")
        t0 = time.time()
        loaded = 0
        with open(MODEL_PATH, "rb") as f:
            mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
            data_start = 8 + header_len
            for name, info in header.items():
                if name == "__metadata__":
                    continue
                dtype = _dtype_map.get(info["dtype"], torch.float32)
                shape = info["shape"]
                off = info["data_offsets"]
                mv = memoryview(mm)[data_start + off[0]:data_start + off[1]]
                tensor = torch.frombuffer(mv, dtype=dtype).reshape(shape)
                if name in model_sd:
                    model_sd[name].copy_(tensor)
                    loaded += 1
                del tensor, mv
            mm.close()

        _model = model.eval()
        _processor = AutoProcessor.from_pretrained(str(MODEL_DIR))
        _model_loaded = True
        print(f"[{time.strftime('%H:%M:%S')}] 模型加载完成: {loaded} tensors, {time.time()-t0:.1f}s")
        return True
    except Exception as e:
        print(f"[{time.strftime('%H:%M:%S')}] 模型加载失败: {e}")
        import traceback
        traceback.print_exc()
        _model_loading = False
        return False
    finally:
        _model_loading = False


def run_inference(image_bytes):
    """运行推理，返回 Markdown 文本。"""
    from PIL import Image
    import io

    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

    prompt = "Parse the document image into structured Markdown with HTML tables and LaTeX formulas."
    messages = [{
        "role": "user",
        "content": [
            {"type": "image", "image": image},
            {"type": "text", "text": prompt},
        ],
    }]

    text = _processor.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    inputs = _processor(text=text, images=[image], return_tensors="pt")

    with _model_lock:
        with torch.no_grad():
            output_ids = _model.generate(**inputs, max_new_tokens=MAX_NEW_TOKENS, do_sample=False)

    trimmed = output_ids[:, inputs.input_ids.shape[1]:]
    result = _processor.batch_decode(
        trimmed, skip_special_tokens=True, clean_up_tokenization_spaces=False
    )
    return result[0]


class Handler(BaseHTTPRequestHandler):
    def _send_json(self, code, data):
        body = json.dumps(data).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/status":
            self._send_json(200, {
                "model_loaded": _model_loaded,
                "model_loading": _model_loading,
                "model_dir": str(MODEL_DIR),
            })
        else:
            self._send_json(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/infer":
            self._send_json(404, {"error": "not found"})
            return

        if not _model_loaded:
            self._send_json(503, {"error": "model not loaded"})
            return

        length = int(self.headers.get("Content-Length", 0))
        if length == 0:
            self._send_json(400, {"error": "empty body"})
            return

        body = self.rfile.read(length)

        try:
            image_bytes = body
            t0 = time.time()
            markdown = run_inference(image_bytes)
            elapsed = int((time.time() - t0) * 1000)
            self._send_json(200, {"markdown": markdown, "elapsed_ms": elapsed})
        except Exception as e:
            self._send_json(500, {"error": str(e)})

    def log_message(self, format, *args):
        print(f"[{time.strftime('%H:%M:%S')}] {args[0]}")


def main():
    load_model()
    server = HTTPServer(("0.0.0.0", PORT), Handler)
    print(f"[{time.strftime('%H:%M:%S')}] WeVisDoc 服务启动: http://0.0.0.0:{PORT}")
    print(f"  GET  /status  → 模型状态")
    print(f"  POST /infer   → 图片推理")
    server.serve_forever()


if __name__ == "__main__":
    main()

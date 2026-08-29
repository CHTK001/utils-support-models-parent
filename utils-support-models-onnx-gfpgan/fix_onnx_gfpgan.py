# -*- coding: utf-8 -*-
"""修复 GFPGAN ONNX 模型：替换 RandomNormalLike 为固定噪声 + 清理 DOUBLE 类型。"""
import numpy as np
import onnx
from onnx import TensorProto, helper, shape_inference

SRC = r'G:\work\utils-support-models-parent\utils-support-models-onnx-gfpgan\src\main\resources\face\restoration\gfpgan\GFPGANv1.3_clean.onnx'
DST = SRC  # 直接覆盖

m = onnx.load(SRC)
g = m.graph

# 1. 收集所有 RandomNormalLike 节点及其输出
rnd_nodes = {}
for n in g.node:
    if n.op_type == 'RandomNormalLike':
        rnd_nodes[n.output[0]] = n
print(f'RandomNormalLike nodes: {len(rnd_nodes)}')

# 2. 为每个 RandomNormalLike 生成固定噪声并作为 initializer 加入
# 用固定种子确保确定性
rng = np.random.RandomState(42)
for out_name in rnd_nodes:
    # 从 value_info 推断 shape
    shape = None
    for vi in g.value_info:
        if vi.name == out_name:
            shape = [d.dim_value for d in vi.type.tensor_type.shape.dim if d.dim_value > 0]
            break
    if shape is None:
        shape = [1, 1, 4, 4]
    # 生成固定噪声
    noise_data = rng.randn(*shape).astype(np.float32)
    tensor = onnx.numpy_helper.from_array(noise_data, out_name)
    g.initializer.append(tensor)
    print(f'  fixed {out_name}: shape={shape}')

# 3. 移除所有 RandomNormalLike 节点
new_g = onnx.GraphProto()
new_g.CopyFrom(g)
new_nodes = [n for n in g.node if n.op_type != 'RandomNormalLike']
del new_g.node[:]
for n in new_nodes:
    new_g.node.add().CopyFrom(n)
m.graph.Clear()
m.graph.CopyFrom(new_g)
print(f'Removed RandomNormalLike nodes, remaining: {len(m.graph.node)}')

# 4. 清理 DOUBLE initializer → FLOAT
cnt_double = 0
for init in m.graph.initializer:
    if init.data_type == TensorProto.DOUBLE:
        arr = onnx.numpy_helper.to_array(init).astype(np.float32)
        init.CopyFrom(onnx.numpy_helper.from_array(arr, init.name))
        cnt_double += 1
print(f'Fixed DOUBLE initializers: {cnt_double}')

# 5. 运行 shape inference 并清理所有 DOUBLE 类型标注
m_checked = shape_inference.infer_shapes(m)
# 替换为 infer 后的模型（保留我们对 initializer 的修改）
# infer_shapes 会重置价值信息，但不会修改 initializer
# 我们需要把 infer 后的 value_info 合并进来
# 更安全：重新 infer 后复制 value_info，然后清理 DOUBLE
new_vi = []
for vi in m_checked.graph.value_info:
    if vi.type.tensor_type.elem_type == TensorProto.DOUBLE:
        vi.type.tensor_type.elem_type = TensorProto.FLOAT
    new_vi.append(vi)

# 清理 graph 中原来的 value_info，替换为新 infer 后的
del g.value_info[:]
g.value_info.extend(new_vi)

cnt_vi = 0
for vi in list(g.value_info) + list(g.input) + list(g.output):
    if vi.type.tensor_type.elem_type == TensorProto.DOUBLE:
        vi.type.tensor_type.elem_type = TensorProto.FLOAT
        cnt_vi += 1
print(f'Fixed value_info type annotations: {cnt_vi}')

# 6. 验证
print('Running checker...')
onnx.checker.check_model(m)
print('Checker passed')

# 7. 保存
onnx.save(m, DST)
print(f'Saved to {DST}')

# 8. 验证确定性
import onnxruntime as ort, time
sess = ort.InferenceSession(DST, providers=['CPUExecutionProvider'])
x = np.random.rand(1, 3, 512, 512).astype(np.float32)
t0 = time.time()
o1 = sess.run(None, {'input': x})[0]
t1 = time.time()
o2 = sess.run(None, {'input': x})[0]
diff = abs(o1 - o2).max()
print(f'Deterministic: 2 runs max_diff={diff:.6f} ({(t1-t0)*1000:.0f}ms/run)')
print('OK' if diff < 1e-6 else '⚠️ NOT deterministic')
print(f'Output range: [{o1.min():.3f}, {o1.max():.3f}]')
print(f'Double initializers after fix: {len([i for i in m.graph.initializer if i.data_type == 7])}')
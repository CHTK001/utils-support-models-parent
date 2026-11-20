# AGENTS.md — utils-support-models-parent

> **模块边界与依赖铁律：[`../规则.md`](../规则.md)（`D:\ch\project\规则.md`），动手前必须先读并遵守。违反 R1/R2 = S0 严重 bug。**
> 全局规则：`C:\Users\Administrator\.config\opencode\AGENTS.md`；源码编辑红线：`C:\Users\Administrator\.agents\GLOBAL-SOURCE-EDITING-RULES.md`。

## 本仓库定位

预训练 ONNX 模型资产库，以 jar 形式发布（GitHub Packages）。**本仓库只有模型资产与打包约定，不含业务规则。**

## 三条铁律（摘要，全文以 `规则.md` 为准）

1. **R1 禁止业务穿插**：这里不得出现任何业务 starter 的业务逻辑；上层也不得重复实现本仓库已提供的能力。
2. **R2 禁止穿透持久层**：跨模块取数只走契约。
3. **R4 缺能力就下沉**：模型加载/推理的通用能力扩到底层，不在上层重造（重复实现 = S0）。

## 交付闸门

`mvn -o -q compile -DskipTests` EXIT=0；编码 `BOM=0 / U+FFFD=0`；模型资产不得随意更名（上层按坐标引用）。

## 提交

只提交自己的文件；资产版本变更必须在同批说明中标注需要同步升级的上层模块。

# Extract DOCX Track Changes

从 Word 文档 (.docx) 中提取所有修订记录 (Track Changes)，输出为 Markdown 格式。

## 功能

提取以下类型的修订：

| 类型 | 说明 |
|------|------|
| 💬 **批注 (Comments)** | 包含批注内容及其对应的原文位置 |
| ❌ **删除 (Deletions)** | 被删除的文本内容，带上下文定位 |
| ➕ **插入 (Insertions)** | 新插入的文本内容，带上下文定位 |
| 🎨 **格式修改 (Formatting)** | 加粗、斜体、颜色、字号等格式变更 |
| 📝 **段落格式 (Paragraph)** | 段落级别的格式修改 |

## 安装

```bash
# 创建虚拟环境
uv venv .venv --python 3.12

# 激活虚拟环境
source .venv/bin/activate

# 安装依赖
uv pip install docx2python
```

## 使用方法

```bash
# 激活虚拟环境
source .venv/bin/activate

# 基础用法 - 输出到终端
python3 extract_docx_track_changes.py manuscript.docx

# 保存到文件
python3 extract_docx_track_changes.py manuscript.docx -o changes.md
```

## 输出示例

```markdown
# Word 文档修改提取结果

## 📊 统计

| 类型 | 数量 |
|------|------|
| 批注 (Comments) | 1 |
| 删除 (Deletions) | 5 |
| 插入 (Insertions) | 4 |
| 格式修改 (Formatting) | 11 |

---

## ❌ 删除内容 (Deletions)

### #1 - 吉星 刘

**时间**: 2025-12-26T16:05:00Z

In this ~~study~~, we developed a 50S/23S‑anchored...

---

## 🎨 格式修改 (Formatting)

### #1 - 吉星 刘

**时间**: 2025-12-26T15:46:00Z

**修改类型**: **加粗**

**修改文本**: couples

...An integrated strategy that [格式修改：couples] ligand‑based...
```

## 依赖

- Python 3.12+
- docx2python

## 技术说明

- 使用 `docx2python` 提取批注及其对应的原文
- 直接解析 `word/document.xml` 提取插入/删除/格式修改
- 格式修改通过比较 `w:rPrChange` 中的新旧格式属性来判断具体类型

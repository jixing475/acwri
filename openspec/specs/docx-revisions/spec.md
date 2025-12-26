# docx-revisions Specification

## Purpose
TBD - created by archiving change add-docx-revisions-extractor. Update Purpose after archive.
## Requirements
### Requirement: Extract Word Document Revisions

系统 SHALL 提供 `extract_docx_revisions()` 函数，用于从 Word 文档中提取所有类型的修订记录（Track Changes），并输出为 Markdown 格式。

#### Scenario: 基本用法 - 提取修订到文件

- **GIVEN** 用户有一个包含 Track Changes 的 Word 文档
- **WHEN** 用户调用 `extract_docx_revisions("manuscript.docx", output = "changes.md")`
- **THEN** 系统应将修订内容保存到 `changes.md` 文件

#### Scenario: 返回字符串

- **GIVEN** 用户有一个包含 Track Changes 的 Word 文档
- **WHEN** 用户调用 `extract_docx_revisions("manuscript.docx")` 不指定 output
- **THEN** 函数应返回包含 Markdown 格式修订内容的字符向量

#### Scenario: 使用自定义 Python 路径

- **GIVEN** 用户配置了独立的 Python 虚拟环境
- **WHEN** 用户调用 `extract_docx_revisions("doc.docx", python_path = "/path/to/.venv/bin/python")`
- **THEN** 系统应使用指定的 Python 可执行文件调用脚本

#### Scenario: 文件不存在错误

- **GIVEN** 用户指定的 docx 文件不存在
- **WHEN** 用户调用 `extract_docx_revisions("nonexistent.docx")`
- **THEN** 系统应抛出友好的错误消息，提示文件不存在

#### Scenario: Python 不可用错误

- **GIVEN** 系统中没有可用的 Python 或 docx2python 未安装
- **WHEN** 用户调用 `extract_docx_revisions("doc.docx")`
- **THEN** 系统应抛出错误消息，提示用户如何设置 Python 环境

### Requirement: Minimal Environment Interference

R wrapper SHALL NOT 自动修改用户的 Python 环境或安装任何 Python 包。

#### Scenario: 不自动安装依赖

- **GIVEN** 用户系统中没有安装 docx2python
- **WHEN** 用户调用 `extract_docx_revisions("doc.docx")`
- **THEN** 系统应报错但不尝试自动安装 Python 包
- **AND** 错误消息应包含如何手动安装依赖的说明

### Requirement: Support All Revision Types

`extract_docx_revisions()` SHALL 支持提取以下类型的修订：

- 💬 批注 (Comments)
- ❌ 删除 (Deletions)
- ➕ 插入 (Insertions)
- 🎨 格式修改 (Formatting)
- 📝 段落格式 (Paragraph)

#### Scenario: 提取所有修订类型

- **GIVEN** Word 文档包含多种类型的 Track Changes
- **WHEN** 用户调用 `extract_docx_revisions("doc.docx")`
- **THEN** 输出应包含所有类型的修订，按类型分组显示


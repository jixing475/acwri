# Change: Add Word Document Revisions Extractor

## Why

Jixing 写了一个 Python 脚本 (`inst/docx2md/extract_docx_track_changes.py`) 用于从 Word 文档中提取 Track Changes（包括批注、删除、插入、格式修改）并输出为 Markdown 格式。现在需要将此功能整合到 `acwri` R 包中，但 R 代码只需简单包装该 Python 脚本，不对环境产生过多干扰。

## What Changes

- **新增 R 函数 `extract_docx_revisions()`**：包装 Python 脚本，提供用户友好的 R 接口
- **最小化环境干扰**：
  - 不自动安装 Python 或依赖项
  - 由用户自行管理 Python 虚拟环境
  - R 只负责调用脚本并处理输出
- **遵循包的现有模式**：使用 `fs::path_package()` 定位脚本

## Impact

- **Affected specs**: 新增 `docx-revisions` capability
- **Affected code**:
  - 新增 `R/docx-revisions.R`
  - 现有 `inst/docx2md/` 保持不变

## Design Considerations

1. **Python 调用方式**: 使用 `base::system2()` 调用 Python 脚本，简单直接
2. **虚拟环境处理**: 
   - 提供 `python_path` 参数让用户指定 Python 可执行路径
   - 默认使用 `"inst/docx2md/.venv"` 里的 python，用户可传入其他 Python 路径
3. **输出处理**:
   - 支持输出到文件或返回字符串
   - 提供 `quiet` 选项控制消息输出
4. **错误处理**: 检查文件存在性、Python 可用性、脚本执行结果

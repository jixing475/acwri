# Tasks: Add Word Document Revisions Extractor

## 1. Implementation

- [x] 1.1 创建 `R/docx-revisions.R` 文件
- [x] 1.2 实现 `extract_docx_revisions()` 主函数
  - 参数：`docx_path`, `output`, `python_path`
  - 使用 `system2()` 调用 Python 脚本
  - 处理输出（返回字符串或写入文件）
- [x] 1.3 实现 `find_python_script()` 内部函数
  - 使用 `fs::path_package()` 定位脚本

## 2. Documentation

- [x] 2.1 为 `extract_docx_revisions()` 添加 roxygen2 文档
- [x] 2.2 更新 `README.md` 添加功能说明和使用示例

## 3. Verification

- [x] 3.1 运行 `devtools::load_all()` 确保无语法错误
- [x] 3.2 手动测试：准备测试 docx 文件，调用函数验证输出
- [x] 3.3 运行 `devtools::check()` 确保包检查通过

## Dependencies

- Python 3.12+ 及 `docx2python` 包由用户自行准备
- R 包无需添加新依赖项

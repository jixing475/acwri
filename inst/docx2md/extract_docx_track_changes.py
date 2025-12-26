#!/usr/bin/env python3
"""
从 Word 文档中提取所有 Track Changes，并包含上下文定位信息
"""

import zipfile
from xml.etree import ElementTree as ET
from docx2python import docx2python
from dataclasses import dataclass
from pathlib import Path
import argparse
import re


W_NS = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'


@dataclass
class Comment:
    id: int
    ref_text: str
    author: str
    date: str
    text: str


@dataclass 
class Revision:
    id: str
    type: str
    author: str
    date: str
    text: str
    context: str = ""  # 上下文定位信息
    detail: str = ""


def extract_comments(docx_path: str) -> list[Comment]:
    comments = []
    with docx2python(docx_path) as docx_content:
        for i, comment_data in enumerate(docx_content.comments, 1):
            ref_text, author, date, comment_text = comment_data
            comments.append(Comment(
                id=i, ref_text=ref_text, author=author, date=date, text=comment_text
            ))
    return comments


def get_paragraph_context(para_elem) -> str:
    """获取段落的完整文本作为上下文"""
    texts = []
    for elem in para_elem.iter():
        if elem.tag == f'{W_NS}t' and elem.text:
            texts.append(elem.text)
        elif elem.tag == f'{W_NS}delText' and elem.text:
            texts.append(f'[已删除：{elem.text}]')
    return ''.join(texts)


def find_parent_paragraph(root, target_elem):
    """找到包含目标元素的段落"""
    # 构建父子关系映射
    parent_map = {}
    for parent in root.iter():
        for child in parent:
            parent_map[child] = parent
    
    current = target_elem
    while current is not None:
        if current.tag == f'{W_NS}p':
            return current
        current = parent_map.get(current)
    return None


def extract_revisions(docx_path: str) -> list[Revision]:
    revisions = []
    
    with zipfile.ZipFile(docx_path, 'r') as docx:
        if 'word/document.xml' not in docx.namelist():
            return revisions
        
        with docx.open('word/document.xml') as f:
            content = f.read()
            root = ET.fromstring(content)
            
            # 构建父子关系映射
            parent_map = {}
            for parent in root.iter():
                for child in parent:
                    parent_map[child] = parent
            
            def find_paragraph(elem):
                current = elem
                while current is not None:
                    if current.tag == f'{W_NS}p':
                        return current
                    current = parent_map.get(current)
                return None
            
            def get_para_text(para):
                if para is None:
                    return ""
                texts = []
                for e in para.iter():
                    if e.tag == f'{W_NS}t' and e.text:
                        texts.append(e.text)
                return ''.join(texts)
            
            def get_context_with_revision(elem, parent_map, rev_type, rev_text):
                """获取包含修订标记的完整上下文"""
                para = find_paragraph(elem)
                if para is None:
                    return ""
                
                # 按顺序收集段落中的所有内容，包括修订标记
                context_parts = []
                
                for child in para:
                    # 检查是否是目标修订元素
                    if child == elem or elem in list(child.iter()):
                        # 插入修订标记
                        if rev_type == 'delete':
                            context_parts.append(f'~~{rev_text}~~')
                        elif rev_type == 'insert':
                            context_parts.append(f'**+{rev_text}+**')
                        elif rev_type == 'formatting':
                            context_parts.append(f'[格式修改：{rev_text}]')
                        continue
                    
                    # 处理普通文本
                    child_texts = []
                    for t in child.iter(f'{W_NS}t'):
                        if t.text:
                            child_texts.append(t.text)
                    # 也处理其他删除的文本（已经接受的修订）
                    for dt in child.iter(f'{W_NS}delText'):
                        if dt.text:
                            child_texts.append(f'~~{dt.text}~~')
                    
                    if child_texts:
                        context_parts.append(''.join(child_texts))
                
                context = ''.join(context_parts)
                
                # 截取有意义的部分，但保留修订标记
                if len(context) > 200:
                    # 找到修订标记的位置
                    if rev_type == 'delete':
                        marker = f'~~{rev_text[:20]}'
                    elif rev_type == 'insert':
                        marker = f'**+{rev_text[:20]}'
                    else:
                        marker = f'[格式修改'
                    
                    pos = context.find(marker)
                    if pos > 0:
                        start = max(0, pos - 50)
                        end = min(len(context), pos + len(rev_text) + 80)
                        context = ('...' if start > 0 else '') + context[start:end] + ('...' if end < len(context) else '')
                
                return context
            
            # 1. 删除 (w:del)
            for elem in root.iter(f'{W_NS}del'):
                rev_id = elem.get(f'{W_NS}id', '')
                author = elem.get(f'{W_NS}author', '')
                date = elem.get(f'{W_NS}date', '')
                
                texts = []
                for dt in elem.iter(f'{W_NS}delText'):
                    if dt.text:
                        texts.append(dt.text)
                text = ''.join(texts)
                
                # 获取上下文（包含修订标记）
                context = get_context_with_revision(elem, parent_map, 'delete', text)
                
                if text.strip():
                    revisions.append(Revision(
                        id=rev_id, type='delete', author=author, date=date,
                        text=text, context=context
                    ))
            
            # 2. 插入 (w:ins)
            for elem in root.iter(f'{W_NS}ins'):
                rev_id = elem.get(f'{W_NS}id', '')
                author = elem.get(f'{W_NS}author', '')
                date = elem.get(f'{W_NS}date', '')
                
                texts = []
                for t in elem.iter(f'{W_NS}t'):
                    if t.text:
                        texts.append(t.text)
                text = ''.join(texts)
                
                # 获取上下文（包含修订标记）
                context = get_context_with_revision(elem, parent_map, 'insert', text)
                
                if text.strip():
                    revisions.append(Revision(
                        id=rev_id, type='insert', author=author, date=date,
                        text=text, context=context
                    ))
            
            # 3. 格式修改 (w:rPrChange)
            def parse_format_details(rpr_change_elem, current_rpr):
                """解析格式修改的具体内容"""
                changes = []
                old_rpr = rpr_change_elem.find(f'{W_NS}rPr')
                
                if old_rpr is None:
                    return "格式修改"
                
                # 检查加粗
                old_bold = old_rpr.find(f'{W_NS}b') is not None
                new_bold = current_rpr.find(f'{W_NS}b') is not None if current_rpr is not None else False
                if old_bold != new_bold:
                    changes.append('**加粗**' if new_bold else '取消加粗')
                
                # 检查斜体
                old_italic = old_rpr.find(f'{W_NS}i') is not None
                new_italic = current_rpr.find(f'{W_NS}i') is not None if current_rpr is not None else False
                if old_italic != new_italic:
                    changes.append('*斜体*' if new_italic else '取消斜体')
                
                # 检查下划线
                old_u = old_rpr.find(f'{W_NS}u') is not None
                new_u = current_rpr.find(f'{W_NS}u') is not None if current_rpr is not None else False
                if old_u != new_u:
                    changes.append('下划线' if new_u else '取消下划线')
                
                # 检查删除线
                old_strike = old_rpr.find(f'{W_NS}strike') is not None
                new_strike = current_rpr.find(f'{W_NS}strike') is not None if current_rpr is not None else False
                if old_strike != new_strike:
                    changes.append('删除线' if new_strike else '取消删除线')
                
                # 检查颜色变更
                old_color = old_rpr.find(f'{W_NS}color')
                new_color = current_rpr.find(f'{W_NS}color') if current_rpr is not None else None
                old_color_val = old_color.get(f'{W_NS}val', '') if old_color is not None else ''
                new_color_val = new_color.get(f'{W_NS}val', '') if new_color is not None else ''
                if old_color_val != new_color_val:
                    if new_color_val:
                        changes.append(f'颜色→#{new_color_val}')
                    elif old_color_val:
                        changes.append(f'颜色#{old_color_val}→默认')
                
                # 检查字号
                old_sz = old_rpr.find(f'{W_NS}sz')
                new_sz = current_rpr.find(f'{W_NS}sz') if current_rpr is not None else None
                old_sz_val = old_sz.get(f'{W_NS}val', '') if old_sz is not None else ''
                new_sz_val = new_sz.get(f'{W_NS}val', '') if new_sz is not None else ''
                if old_sz_val != new_sz_val:
                    old_pt = int(old_sz_val)//2 if old_sz_val.isdigit() else '?'
                    new_pt = int(new_sz_val)//2 if new_sz_val.isdigit() else '?'
                    changes.append(f'字号:{old_pt}pt→{new_pt}pt')
                
                # 检查高亮
                old_hl = old_rpr.find(f'{W_NS}highlight')
                new_hl = current_rpr.find(f'{W_NS}highlight') if current_rpr is not None else None
                if (old_hl is not None) != (new_hl is not None):
                    if new_hl is not None:
                        changes.append(f'高亮 ({new_hl.get(f"{W_NS}val", "")})')
                    else:
                        changes.append('取消高亮')
                
                return ', '.join(changes) if changes else '格式微调'
            
            for elem in root.iter(f'{W_NS}rPrChange'):
                rev_id = elem.get(f'{W_NS}id', '')
                author = elem.get(f'{W_NS}author', '')
                date = elem.get(f'{W_NS}date', '')
                
                # 获取被修改格式的文本（在父 run 元素中）
                rpr = parent_map.get(elem)  # 当前 rPr
                run = parent_map.get(rpr) if rpr is not None else None  # 父 run
                
                if run is not None:
                    texts = []
                    for t in run.iter(f'{W_NS}t'):
                        if t.text:
                            texts.append(t.text)
                    text = ''.join(texts)
                else:
                    text = ''
                
                # 解析具体的格式修改
                detail = parse_format_details(elem, rpr)
                
                # 获取上下文（包含修订标记）
                context = get_context_with_revision(elem, parent_map, 'formatting', text)
                
                revisions.append(Revision(
                    id=rev_id, type='formatting', author=author, date=date,
                    text=text, context=context, detail=detail
                ))
            
            # 4. 段落格式修改
            for elem in root.iter(f'{W_NS}pPrChange'):
                rev_id = elem.get(f'{W_NS}id', '')
                author = elem.get(f'{W_NS}author', '')
                date = elem.get(f'{W_NS}date', '')
                
                para = find_paragraph(elem)
                context = get_para_text(para)[:100] if para is not None else ""
                
                revisions.append(Revision(
                    id=rev_id, type='paragraph', author=author, date=date,
                    text='', context=context, detail='段落格式修改'
                ))
    
    revisions.sort(key=lambda r: int(r.id) if r.id.isdigit() else 0)
    return revisions


def format_markdown(comments: list[Comment], revisions: list[Revision]) -> str:
    lines = ["# Word 文档修改提取结果", ""]
    
    deletes = [r for r in revisions if r.type == 'delete']
    inserts = [r for r in revisions if r.type == 'insert']
    formatting = [r for r in revisions if r.type == 'formatting']
    paragraphs = [r for r in revisions if r.type == 'paragraph']
    
    lines.extend([
        "## 📊 统计", "",
        "| 类型 | 数量 |",
        "|------|------|",
        f"| 批注 (Comments) | {len(comments)} |",
        f"| 删除 (Deletions) | {len(deletes)} |",
        f"| 插入 (Insertions) | {len(inserts)} |",
        f"| 格式修改 (Formatting) | {len(formatting)} |",
        f"| 段落格式 (Paragraph) | {len(paragraphs)} |",
        "", "---", ""
    ])
    
    # 批注
    if comments:
        lines.extend(["## 💬 批注 (Comments)", ""])
        for c in comments:
            ref = c.ref_text[:200] + '...' if len(c.ref_text) > 200 else c.ref_text
            lines.extend([
                f"### #{c.id} - {c.author}", "",
                f"**时间**: {c.date}", "",
                f"**原文**: > {ref}", "",
                f"**批注**: {c.text}", "",
                "---", ""
            ])
    
    # 删除
    if deletes:
        lines.extend(["## ❌ 删除内容 (Deletions)", ""])
        for i, r in enumerate(deletes, 1):
            lines.extend([
                f"### #{i} - {r.author}", "",
                f"**时间**: {r.date}", "",
            ])
            if r.context:
                lines.append(f"{r.context}")
                lines.append("")
            else:
                text = r.text[:300] + '...' if len(r.text) > 300 else r.text
                lines.append(f"~~{text}~~")
                lines.append("")
            lines.extend(["---", ""])
    
    # 插入
    if inserts:
        lines.extend(["## ➕ 插入内容 (Insertions)", ""])
        for i, r in enumerate(inserts, 1):
            lines.extend([
                f"### #{i} - {r.author}", "",
                f"**时间**: {r.date}", "",
            ])
            if r.context:
                lines.append(f"{r.context}")
                lines.append("")
            else:
                text = r.text[:300] + '...' if len(r.text) > 300 else r.text
                lines.append(f"**+{text}+**")
                lines.append("")
            lines.extend(["---", ""])
    
    # 格式修改
    if formatting:
        lines.extend(["## 🎨 格式修改 (Formatting)", ""])
        for i, r in enumerate(formatting, 1):
            lines.append(f"### #{i} - {r.author}")
            lines.append("")
            lines.append(f"**时间**: {r.date}")
            lines.append("")
            lines.append(f"**修改类型**: {r.detail}")
            lines.append("")
            if r.text:
                lines.append(f"**修改文本**: {r.text[:100]}{'...' if len(r.text) > 100 else ''}")
                lines.append("")
            if r.context:
                lines.append(f"{r.context}")
                lines.append("")
            lines.extend(["---", ""])
    
    # 段落格式
    if paragraphs:
        lines.extend(["## 📝 段落格式修改 (Paragraph)", ""])
        for i, r in enumerate(paragraphs, 1):
            lines.extend([
                f"### #{i} - {r.author}", "",
                f"**时间**: {r.date}", "",
            ])
            if r.context:
                lines.append(f"**段落内容**: {r.context}...")
                lines.append("")
            lines.extend(["---", ""])
    
    if not comments and not revisions:
        lines.append("*文档中没有任何修订*")
    
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description='从 Word 文档中提取所有 Track Changes')
    parser.add_argument('docx_file', help='Word 文档路径')
    parser.add_argument('-o', '--output', help='输出文件路径')
    
    args = parser.parse_args()
    
    if not Path(args.docx_file).exists():
        print(f"错误：文件 {args.docx_file} 不存在")
        return 1
    
    comments = extract_comments(args.docx_file)
    revisions = extract_revisions(args.docx_file)
    output = format_markdown(comments, revisions)
    
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(output)
        print(f"结果已保存到 {args.output}")
    else:
        print(output)
    
    return 0


if __name__ == '__main__':
    exit(main())

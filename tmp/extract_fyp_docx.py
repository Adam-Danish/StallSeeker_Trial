from pathlib import Path
import json
import sys

from docx import Document
from docx.table import Table
from docx.text.paragraph import Paragraph


def extract(path: Path):
    doc = Document(path)
    blocks = []
    for item in doc.iter_inner_content():
        if isinstance(item, Paragraph):
            text = item.text.strip()
            if text:
                blocks.append({"type": "paragraph", "style": item.style.name, "text": text})
        elif isinstance(item, Table):
            rows = []
            for row in item.rows:
                rows.append([cell.text.strip() for cell in row.cells])
            blocks.append({"type": "table", "rows": rows})
    for section_index, section in enumerate(doc.sections, start=1):
        for area_name, area in (("header", section.header), ("footer", section.footer)):
            texts = [p.text.strip() for p in area.paragraphs if p.text.strip()]
            if texts:
                blocks.append({"type": area_name, "section": section_index, "texts": texts})
    return {"path": str(path), "blocks": blocks}


print(json.dumps([extract(Path(p)) for p in sys.argv[1:]], indent=2, ensure_ascii=False))

from copy import deepcopy
from hashlib import sha256
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from lxml import etree


REFERENCE = Path(r"C:\GMi\SEM 5\FYP 2\Task Checklist Template (1).docx")
OUTPUT = Path(r"C:\Others\SE\Flutter Projects\StallSeeker_Trial\docs\StallSeeker FYP2 Task Checklist.docx")
EXPECTED_SHA256 = "639526EF0C269385814B8E8529DE2A4E6A5A1B711DB301D776BBEBF69B221EAA"

W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
NS = {"w": W_NS}


def w(local):
    return f"{{{W_NS}}}{local}"


def replace_cell(cell, lines, *, bold=False, align="left", size=20, keep_next=False):
    tc_pr = cell.find(w("tcPr"))
    for child in list(cell):
        if child is not tc_pr:
            cell.remove(child)

    if tc_pr is None:
        tc_pr = etree.Element(w("tcPr"))
        cell.insert(0, tc_pr)
    v_align = tc_pr.find(w("vAlign"))
    if v_align is None:
        v_align = etree.SubElement(tc_pr, w("vAlign"))
    v_align.set(w("val"), "center")

    values = lines if isinstance(lines, list) else [lines]
    if not values:
        values = [""]
    for value in values:
        p = etree.SubElement(cell, w("p"))
        p_pr = etree.SubElement(p, w("pPr"))
        jc = etree.SubElement(p_pr, w("jc"))
        jc.set(w("val"), align)
        spacing = etree.SubElement(p_pr, w("spacing"))
        spacing.set(w("before"), "0")
        spacing.set(w("after"), "0")
        if keep_next:
            etree.SubElement(p_pr, w("keepNext"))

        if value:
            r = etree.SubElement(p, w("r"))
            r_pr = etree.SubElement(r, w("rPr"))
            fonts = etree.SubElement(r_pr, w("rFonts"))
            for name in ("ascii", "hAnsi", "cs"):
                fonts.set(w(name), "Arial")
            sz = etree.SubElement(r_pr, w("sz"))
            sz.set(w("val"), str(size))
            sz_cs = etree.SubElement(r_pr, w("szCs"))
            sz_cs.set(w("val"), str(size))
            if bold:
                etree.SubElement(r_pr, w("b"))
                etree.SubElement(r_pr, w("bCs"))
            t = etree.SubElement(r, w("t"))
            if value.startswith(" ") or value.endswith(" "):
                t.set("{http://www.w3.org/XML/1998/namespace}space", "preserve")
            t.text = value


def prepare_row(row, *, repeat_header=False):
    tr_pr = row.find(w("trPr"))
    if tr_pr is None:
        tr_pr = etree.Element(w("trPr"))
        row.insert(0, tr_pr)
    if tr_pr.find(w("cantSplit")) is None:
        etree.SubElement(tr_pr, w("cantSplit"))
    if repeat_header and tr_pr.find(w("tblHeader")) is None:
        etree.SubElement(tr_pr, w("tblHeader"))


SECTIONS = [
    (
        "INFORMATION GATHERING",
        [
            ("Confirm problem statement, objectives, scope and measurable success criteria", "TBC", "Adam Danish", ""),
            ("Finalise requirements and user stories for customer, vendor and guest roles", "TBC", "Adam Danish", ""),
            ("Complete system design covering Flutter architecture, Firebase data, maps, notifications and security", "TBC", "Adam Danish", ""),
        ],
    ),
    (
        "DEVELOPMENT",
        [
            ("Set up Flutter project architecture, dependencies and application theme", "27/07/2026", "Adam Danish", "X"),
            ("Configure Firebase Core, Authentication, Firestore and Storage", "27/07-04/08/2026", "Adam Danish", "X"),
            ("Create application models, collection constants and service layer", "27/07-05/08/2026", "Adam Danish", "X"),
            ("Implement email and password authentication with customer and vendor role routing", "29/07-06/09/2026", "Adam Danish", "X"),
            ("Implement guest access and Google Sign-In", "06/08-12/08/2026", "Adam Danish", "X"),
            ("Implement verification, password, email and account lifecycle flows", "06/08-06/09/2026", "Adam Danish", "X"),
            ("Build vendor profile, stall details, opening hours, description and stall image features", "03/08-14/08/2026", "Adam Danish", "X"),
            ("Build vendor dashboard with location sharing and open or closed stall status", "03/08-25/08/2026", "Adam Danish", "X"),
            ("Build vendor menu create, edit and delete flows with image, price and availability status", "03/08-14/08/2026", "Adam Danish", "X"),
            ("Build customer map discovery using GPS and manually selected locations", "03/08-06/09/2026", "Adam Danish", "X"),
            ("Add stall search, category, map-bound, distance and radius filtering", "03/08-06/09/2026", "Adam Danish", "X"),
            ("Build stall cards and details with menu, availability, freshness and refresh handling", "03/08-06/09/2026", "Adam Danish", "X"),
            ("Implement follow and unfollow actions with the customer following list", "05/08-25/08/2026", "Adam Danish", "X"),
            ("Implement FCM push notifications and follower alerts for stall status updates", "06/08-06/09/2026", "Adam Danish", "X"),
            ("Implement notification history, unread state and notification preferences", "06/09/2026", "Adam Danish", "X"),
            ("Add directions using Google Maps, Waze and browser fallback", "25/08/2026", "Adam Danish", "X"),
            ("Complete profile, account, About, FAQ, legal and logout screens", "06/08-06/09/2026", "Adam Danish", "X"),
            ("Refine splash, welcome, navigation, responsive UI, loading and error states", "06/08-06/09/2026", "Adam Danish", "X"),
            ("Configure production secrets, Firestore rules, indexes and deploy Cloud Functions", "TBC", "Adam Danish", ""),
            ("Prepare signed Android release build and final distribution package", "TBC", "Adam Danish", ""),
        ],
    ),
    (
        "TESTING",
        [
            ("Run backend notification-history unit tests and confirm all cases pass", "10/09/2026", "Adam Danish", "X"),
            ("Run Flutter static analysis and resolve all warnings and errors", "TBC", "Adam Danish", ""),
            ("Test registration, verification, login, Google login, guest mode and role routing", "TBC", "Adam Danish", ""),
            ("Test password, email, profile, logout and account deletion flows", "TBC", "Adam Danish", ""),
            ("Test vendor profile, live location, stall status and complete menu CRUD", "TBC", "Adam Danish", ""),
            ("Test customer GPS and manual location, search, filters, stall details and directions", "TBC", "Adam Danish", ""),
            ("Test following, push notifications, notification history and offline or error recovery", "TBC", "Adam Danish", ""),
            ("Validate Firestore and Storage rules plus callable function permissions", "TBC", "Adam Danish", ""),
            ("Run Android device regression, usability and release-build testing", "TBC", "Adam Danish", ""),
        ],
    ),
    (
        "DOCUMENTATION",
        [
            ("Update Chapters 1 to 3 with the final scope, literature review, methodology and system design", "TBC", "Adam Danish", ""),
            ("Write the implementation chapter with architecture, Firebase services and key feature evidence", "TBC", "Adam Danish", ""),
            ("Write the testing and evaluation chapter with cases, results, findings and limitations", "TBC", "Adam Danish", ""),
            ("Prepare user manual, administrator notes and deployment configuration guide", "TBC", "Adam Danish", ""),
            ("Update diagrams, screenshots, references, appendices and traceability evidence", "TBC", "Adam Danish", ""),
            ("Proofread and format the final report according to institutional requirements", "TBC", "Adam Danish", ""),
        ],
    ),
    (
        "PROGRESS PRESENTATION 1",
        [
            ("Prepare slides, demonstration flow and progress evidence for the first review", "TBC", "Adam Danish", ""),
            ("Deliver the first progress presentation and record reviewer feedback", "TBC", "Adam Danish", ""),
        ],
    ),
    (
        "PROGRESS PRESENTATION 2",
        [
            ("Prepare updated slides, test evidence and demonstration for the second review", "TBC", "Adam Danish", ""),
            ("Deliver the second progress presentation and record required corrections", "TBC", "Adam Danish", ""),
        ],
    ),
    (
        "INTERNAL PRESENTATION",
        [
            ("Complete internal presentation slides, poster or supporting material and timed demo rehearsal", "TBC", "Adam Danish", ""),
            ("Deliver the internal presentation and apply supervisor or panel corrections", "TBC", "Adam Danish", ""),
        ],
    ),
    (
        "EXTERNAL PRESENTATION",
        [
            ("Freeze the tested release, final report, user manual, slides and backup demonstration assets", "TBC", "Adam Danish", ""),
            ("Deliver the external presentation and final demonstration, then archive submission evidence", "TBC", "Adam Danish", ""),
        ],
    ),
]


def build_document_xml(xml_bytes):
    parser = etree.XMLParser(remove_blank_text=False)
    root = etree.fromstring(xml_bytes, parser)
    body = root.find("w:body", NS)
    tables = body.findall("w:tbl", NS)
    if len(tables) != 2:
        raise RuntimeError(f"Expected 2 tables, found {len(tables)}")

    metadata, checklist = tables
    metadata_rows = metadata.findall("w:tr", NS)
    replace_cell(metadata_rows[0].findall("w:tc", NS)[1], "SET/____/____", size=20)
    replace_cell(metadata_rows[1].findall("w:tc", NS)[1], "StallSeeker Food Stall Discovery Application", size=20)
    replace_cell(metadata_rows[2].findall("w:tc", NS)[1], ["1. Adam Danish", "2.", "3.", "4."], size=20)
    replace_cell(metadata_rows[3].findall("w:tc", NS)[1], "____________________________", size=20)

    source_rows = checklist.findall("w:tr", NS)
    if len(source_rows) < 3:
        raise RuntimeError("Checklist table does not contain reusable row patterns")
    header_template = deepcopy(source_rows[0])
    section_template = deepcopy(source_rows[1])
    data_template = deepcopy(source_rows[2])

    tbl_pr = checklist.find(w("tblPr"))
    if tbl_pr is not None:
        layout = tbl_pr.find(w("tblLayout"))
        if layout is None:
            layout = etree.SubElement(tbl_pr, w("tblLayout"))
        layout.set(w("type"), "fixed")

    for row in source_rows:
        checklist.remove(row)

    header = deepcopy(header_template)
    prepare_row(header, repeat_header=True)
    header_values = ["No.", "TASK", "DATE(s)", "PERSON IN CHARGE", "TICK / ONCE DONE"]
    for cell, value in zip(header.findall("w:tc", NS), header_values):
        replace_cell(cell, value, bold=True, align="center", size=20)
    checklist.append(header)

    item_number = 1
    for section_name, items in SECTIONS:
        section_row = deepcopy(section_template)
        prepare_row(section_row)
        section_cells = section_row.findall("w:tc", NS)
        for index, cell in enumerate(section_cells):
            replace_cell(
                cell,
                section_name if index == 1 else "",
                bold=True,
                align="left" if index == 1 else "center",
                size=20,
                keep_next=True,
            )
        checklist.append(section_row)

        for task, date, owner, status in items:
            row = deepcopy(data_template)
            prepare_row(row)
            cells = row.findall("w:tc", NS)
            values = [str(item_number), task, date, owner, status]
            for index, (cell, value) in enumerate(zip(cells, values)):
                replace_cell(
                    cell,
                    value,
                    align="left" if index == 1 else "center",
                    size=20,
                )
            checklist.append(row)
            item_number += 1

    for paragraph in list(body.findall("w:p", NS)):
        text = "".join(paragraph.itertext()).strip()
        if text.startswith("(LIST YOUR TASKS AS DETAIL AS POSSIBLE"):
            body.remove(paragraph)

    return etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone="yes")


def main():
    actual_hash = sha256(REFERENCE.read_bytes()).hexdigest().upper()
    if actual_hash != EXPECTED_SHA256:
        raise RuntimeError(f"Reference hash mismatch: {actual_hash}")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(REFERENCE, "r") as source:
        document_xml = build_document_xml(source.read("word/document.xml"))
        with ZipFile(OUTPUT, "w") as destination:
            for info in source.infolist():
                data = document_xml if info.filename == "word/document.xml" else source.read(info.filename)
                destination.writestr(info, data, compress_type=info.compress_type or ZIP_DEFLATED)

    print(f"Created {OUTPUT}")
    print(f"Tasks: {sum(len(items) for _, items in SECTIONS)}")


if __name__ == "__main__":
    main()

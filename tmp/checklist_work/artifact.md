# Template execution contract

## Reference

- Retained reference: `C:\GMi\SEM 5\FYP 2\Task Checklist Template (1).docx`
- SHA-256: `639526EF0C269385814B8E8529DE2A4E6A5A1B711DB301D776BBEBF69B221EAA`
- Size: 13,545 bytes
- Pages: 1 in the Word PDF reference render
- Sections: 1
- Render evidence: `C:\Others\SE\Flutter Projects\StallSeeker_Trial\tmp\checklist_work\template-reference-render`
- Style evidence: `C:\Others\SE\Flutter Projects\StallSeeker_Trial\tmp\checklist_work\template-style-evidence.json`

## Page system

- Letter portrait, 8.50 by 11.00 inches.
- Margins: 1.00 inch on all sides.
- One continuous text column. No distinct first, odd, or even page treatment.
- Header and footer parts are absent; the exposed header and footer paragraphs are empty.

## Typography and components

- All visible text uses Arial in black.
- Title: centered, 16 pt, bold, underlined, exact source text `FYP2 TASK CHECKLIST`.
- Metadata table: 2 columns with widths approximately 1.87 and 4.63 inches. Labels and values are Arial 10 pt with black grid borders.
- Task table: 5 columns with widths approximately 0.49, 2.56, 1.18, 1.28, and 1.18 inches. Source table width is 6.50 inches.
- Task header row: light gray fill `D0CECE`; bold Arial; short labels centered except the source date label, which may be centered in the filled version for consistency.
- Section rows: blank number/date/person/status cells and a bold uppercase label in the task column.
- Data rows: number, date, person, and completion status centered; task description left aligned.
- Source cells use the Table Grid style and default cell margins. Rows expand naturally; no fixed heights.
- The header row must repeat on continuation pages. Rows must not split across pages.

## Content flow and slot map

1. `word/document.xml/body/p[1]`: preserve title text and visual treatment.
2. `word/document.xml/body/tbl[1]`: edit metadata values only.
   - Row 1 column 2: group code; keep a fillable placeholder because the repository does not establish the official code.
   - Row 2 column 2: replace with the project title.
   - Row 3 column 2: enter the repository contributor as member 1 and retain blank numbered lines for any additional members.
   - Row 4 column 2: retain a fillable blank for the supervisor name.
3. `word/document.xml/body/tbl[2]`: preserve the five-column schema and replace sample tasks with StallSeeker-specific checklist rows. New rows may clone the source section and data row patterns. Preserve column geometry, borders, font family, and header fill.
4. Final guidance paragraph: remove it from the completed checklist because it is template-filling guidance rather than checklist content.
5. Blank spacer paragraphs: retain only enough spacing to preserve the source-derived first-page hierarchy; do not force a one-page layout.

## Project content evidence

- Repository: Flutter application named StallSeeker for food-stall discovery.
- Implemented areas evidenced by source and Git history: Firebase initialization; authentication and role routing; guest and Google sign-in; vendor profiles, menu CRUD, images, location, and open status; customer map discovery, location selection, search/filtering, stall details, following, directions, push notifications and notification history; profile and account settings; callable backend functions.
- Git history identifies Adam Danish as the contributor and implementation dates from 27 July to 6 September 2026.
- The backend notification-history unit suite passed 5 of 5 tests on 10 September 2026.
- Unverified or institution-controlled items must remain pending or fillable: formal requirement sign-off, official group code, supervisor, formal report chapters, presentation dates, production deployment, full Flutter static analysis, release build, device/UAT evidence, and final submission.

## Package preservation

- Editable package part: `word/document.xml` only.
- Preserve-only parts and SHA-256 hashes:
  - `[Content_Types].xml` `dfa90f373b8fd8147ee3e4bfe1ee059e536cc1b068f7ec140c3fc0e6554f331a`
  - `_rels/.rels` `e19238d7a71fa7a2490776252686f70e2de6238c87cd509b5e3a3cc07c2ea4df`
  - `word/_rels/document.xml.rels` `b725d5476e76f555fc24ecb908474fd29b671687336e5e1177a5c4c35cb5939f`
  - `word/theme/theme1.xml` `2fc1eb21b61950e440496e896ec96386689edad2ca3bd95df0c134b32afe6431`
  - `word/settings.xml` `c969d5d7bd3a0d743b0abff6d1f36738e4793f189a6d5e3c67ab0256399b2e8b`
  - `word/fontTable.xml` `d0d123ad2a57fab27e0ce9fc8116e9d0898161238c6b9b47515b2821be43f1dc`
  - `word/webSettings.xml` `2239eb14f7025b258bc57fa5dcb53c4ec4db834a9820e2b4d8ae70af5a4f0345`
  - `docProps/app.xml` `a81f483cbeddf67e746301bda297e8ea71fa15ed5177146b8ad278427bcd879a`
  - `docProps/core.xml` `2b371b1c2d51f44e23107efa4ba1b243e4b78ca5862283d350f7f1c70349b4b6`
  - `word/styles.xml` `e342db802c5f422501be7fcffc19c3dae97f4f9876e23c073af5a51746c72b81`

## Fidelity gates

- The retained reference must remain byte-for-byte unchanged at its recorded hash.
- Final page size, margins, title styling, metadata table structure, task-table columns, gray header, borders, and Arial typography must remain source-derived.
- Expected differences are limited to metadata values, the expanded task rows, repeating header behavior, page count, and removal of the final template guidance paragraph.
- Inspect every rendered final page for clipping, split rows, border loss, cramped wrapping, missing tick glyphs, and unexpected blank pages.

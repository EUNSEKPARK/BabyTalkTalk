const fs = require("fs");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, LevelFormat,
  HeadingLevel, BorderStyle, WidthType, ShadingType, PageNumber, PageBreak,
  TabStopType, TabStopPosition
} = require("docx");

// Colors
const MINT = "46F1C5";
const DARK_BG = "111125";
const NAVY = "1E1E32";
const LIGHT_TEXT = "F0EEFF";
const WHITE = "FFFFFF";
const MID_GRAY = "D5DDD8";
const SECTION_BG = "EEF9F5";
const TABLE_HEADER = "E8F5F0";
const TABLE_BORDER = "D0E8DE";
const ACCENT_ORANGE = "FFD268";
const ACCENT_PURPLE = "C5C4E2";

const border = { style: BorderStyle.SINGLE, size: 1, color: TABLE_BORDER };
const borders = { top: border, bottom: border, left: border, right: border };
const cellMargin = { top: 60, bottom: 60, left: 100, right: 100 };

function headerCell(text, width) {
  return new TableCell({
    borders,
    width: { size: width, type: WidthType.DXA },
    shading: { fill: TABLE_HEADER, type: ShadingType.CLEAR },
    margins: cellMargin,
    verticalAlign: "center",
    children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text, bold: true, font: "Arial", size: 20 })] })],
  });
}

function cell(text, width, opts = {}) {
  return new TableCell({
    borders,
    width: { size: width, type: WidthType.DXA },
    margins: cellMargin,
    verticalAlign: "center",
    children: [new Paragraph({
      alignment: opts.center ? AlignmentType.CENTER : AlignmentType.LEFT,
      children: [new TextRun({ text, font: "Arial", size: 20, ...(opts.bold ? { bold: true } : {}), ...(opts.color ? { color: opts.color } : {}) })],
    })],
  });
}

function heading1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 360, after: 200 },
    children: [new TextRun({ text, bold: true, font: "Arial", size: 36, color: "1A6B55" })],
  });
}

function heading2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 280, after: 160 },
    children: [new TextRun({ text, bold: true, font: "Arial", size: 28, color: "2D8B73" })],
  });
}

function heading3(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 200, after: 120 },
    children: [new TextRun({ text, bold: true, font: "Arial", size: 24, color: "3A9D84" })],
  });
}

function body(text, opts = {}) {
  return new Paragraph({
    spacing: { after: 120 },
    children: [new TextRun({ text, font: "Arial", size: 22, ...(opts.bold ? { bold: true } : {}), ...(opts.italic ? { italics: true } : {}) })],
  });
}

function tipBox(title, content) {
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [9360],
    rows: [new TableRow({
      children: [new TableCell({
        borders: { top: { style: BorderStyle.SINGLE, size: 3, color: MINT }, bottom: border, left: border, right: border },
        width: { size: 9360, type: WidthType.DXA },
        shading: { fill: SECTION_BG, type: ShadingType.CLEAR },
        margins: { top: 100, bottom: 100, left: 160, right: 160 },
        children: [
          new Paragraph({ spacing: { after: 60 }, children: [new TextRun({ text: title, bold: true, font: "Arial", size: 20, color: "1A6B55" })] }),
          new Paragraph({ children: [new TextRun({ text: content, font: "Arial", size: 20 })] }),
        ],
      })],
    })],
  });
}

function spacer(h = 120) {
  return new Paragraph({ spacing: { after: h }, children: [] });
}

const doc = new Document({
  styles: {
    default: { document: { run: { font: "Arial", size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 36, bold: true, font: "Arial", color: "1A6B55" },
        paragraph: { spacing: { before: 360, after: 200 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 28, bold: true, font: "Arial", color: "2D8B73" },
        paragraph: { spacing: { before: 280, after: 160 }, outlineLevel: 1 } },
      { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: "Arial", color: "3A9D84" },
        paragraph: { spacing: { before: 200, after: 120 }, outlineLevel: 2 } },
    ]
  },
  numbering: {
    config: [
      { reference: "bullets", levels: [{ level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
      { reference: "bullets2", levels: [{ level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
      { reference: "numbers", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
      { reference: "numbers2", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
      { reference: "numbers3", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
      { reference: "numbers4", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
      { reference: "numbers5", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    ]
  },
  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840 },
        margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 },
      },
    },
    headers: {
      default: new Header({
        children: [new Paragraph({
          alignment: AlignmentType.RIGHT,
          children: [new TextRun({ text: "ChatBabyTime \uC0AC\uC6A9 \uC124\uBA85\uC11C", font: "Arial", size: 16, color: "999999", italics: true })],
        })],
      }),
    },
    footers: {
      default: new Footer({
        children: [new Paragraph({
          alignment: AlignmentType.CENTER,
          children: [new TextRun({ text: "- ", font: "Arial", size: 16, color: "AAAAAA" }), new TextRun({ children: [PageNumber.CURRENT], font: "Arial", size: 16, color: "AAAAAA" }), new TextRun({ text: " -", font: "Arial", size: 16, color: "AAAAAA" })],
        })],
      }),
    },
    children: [
      // ========== COVER PAGE ==========
      spacer(600),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 80 }, children: [new TextRun({ text: "\uD83D\uDC76", font: "Arial", size: 80 })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 40 }, children: [new TextRun({ text: "ChatBabyTime", font: "Arial", size: 56, bold: true, color: "1A6B55" })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 }, children: [new TextRun({ text: "\uC790\uC5F0\uC5B4 \uC74C\uC131 \uC721\uC544 \uAE30\uB85D \uC571", font: "Arial", size: 28, color: "666666" })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 60 }, children: [new TextRun({ text: "\uC571 \uC0AC\uC6A9 \uC124\uBA85\uC11C", font: "Arial", size: 32, bold: true })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 400 }, children: [new TextRun({ text: "v1.0", font: "Arial", size: 22, color: "999999" })] }),

      // Decorative line
      new Paragraph({
        alignment: AlignmentType.CENTER,
        border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: MINT, space: 1 } },
        spacing: { after: 200 },
        children: [],
      }),

      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 100 }, children: [new TextRun({ text: "\uD55C\uAD6D\uC5B4 \uC790\uC5F0\uC5B4/\uC74C\uC131\uC73C\uB85C \uC544\uAE30\uC758 \uC218\uC720, \uC218\uBA74, \uAE30\uC800\uADC0, \uAC74\uAC15\uC744 \uAC04\uD3B8\uD558\uAC8C \uAE30\uB85D\uD558\uC138\uC694.", font: "Arial", size: 22, color: "555555" })] }),

      new Paragraph({ children: [new PageBreak()] }),

      // ========== 1. 앱 소개 ==========
      heading1("1. \uC571 \uC18C\uAC1C"),
      body("ChatBabyTime\uC740 \uD55C\uAD6D\uC5B4 \uC790\uC5F0\uC5B4 \uBC0F \uC74C\uC131 \uC785\uB825\uC73C\uB85C \uC544\uAE30\uC758 \uC721\uC544 \uAE30\uB85D\uC744 \uC27D\uACE0 \uBE60\uB974\uAC8C \uAD00\uB9AC\uD560 \uC218 \uC788\uB294 \uC2A4\uB9C8\uD2B8 \uC721\uC544 \uAE30\uB85D \uC571\uC785\uB2C8\uB2E4."),
      body("\"\uBD84\uC720 120ml \uBA39\uC5C8\uC5B4\"\uB77C\uACE0 \uB9D0\uD558\uAC70\uB098 \uC785\uB825\uD558\uBA74, AI\uAC00 \uC790\uB3D9\uC73C\uB85C \uCE74\uD14C\uACE0\uB9AC\uC640 \uC591, \uC2DC\uAC04\uC744 \uBD84\uC11D\uD558\uC5EC \uAE30\uB85D\uD569\uB2C8\uB2E4."),
      spacer(60),

      heading2("1.1 \uC8FC\uC694 \uD2B9\uC9D5"),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uD55C\uAD6D\uC5B4 \uC790\uC5F0\uC5B4 \uC785\uB825: \"\uBD84\uC720 120ml \uBA39\uC5C8\uC5B4\" \uAC19\uC740 \uC77C\uC0C1\uC801\uC778 \uBB38\uC7A5\uC73C\uB85C \uAE30\uB85D", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uC74C\uC131 \uC785\uB825: \uC190\uC774 \uBC14\uC058 \uB54C \uB9D0\uB85C \uAE30\uB85D", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uBE60\uB978 \uCE74\uD14C\uACE0\uB9AC \uC785\uB825: \uC544\uC774\uCF58 \uD130\uCE58\uB85C \uD55C \uBC88\uC5D0 \uAE30\uB85D", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uC2A4\uB9C8\uD2B8 \uC2DC\uAC04 \uCD94\uB860: \"\uC624\uD6C4 2\uC2DC\"\uB97C \uC790\uB3D9 \uD310\uB2E8 (AM/PM \uBE44\uAD50)", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uD0C0\uC784\uB77C\uC778 \uBDF0: \uB0A0\uC9DC\uBCC4 \uAE30\uB85D\uC744 \uC2DC\uAC01\uC801\uC73C\uB85C \uD655\uC778", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uD328\uD134 \uBD84\uC11D: \uC218\uC720/\uC218\uBA74/\uAE30\uC800\uADC0 \uAC04\uACA9 \uBC0F \uC8FC\uAC04 \uD328\uD134", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uD1B5\uACC4 \uCC28\uD2B8: \uC218\uC720\uB7C9, \uC218\uBA74\uC2DC\uAC04 \uB4F1 \uC2DC\uAC01\uD654", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uC131\uC7A5 \uBCF4\uACE0\uC11C: AI \uAE30\uBC18 \uC8FC\uAC04 \uBD84\uC11D \uBC0F \uB9C8\uC77C\uC2A4\uD1A4 \uCCB4\uD06C\uB9AC\uC2A4\uD2B8", font: "Arial", size: 22 })] }),

      spacer(60),
      heading2("1.2 \uD654\uBA74 \uAD6C\uC131 (4\uD0ED)"),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [1400, 1800, 6160],
        rows: [
          new TableRow({ children: [headerCell("\uD0ED", 1400), headerCell("\uD654\uBA74\uBA85", 1800), headerCell("\uC124\uBA85", 6160)] }),
          new TableRow({ children: [cell("\u2460", 1400, { center: true }), cell("\uAE30\uB85D", 1800, { bold: true }), cell("\uBA54\uC778 \uD654\uBA74. \uCE74\uD14C\uACE0\uB9AC \uBE60\uB978\uC785\uB825, \uD14D\uC2A4\uD2B8/\uC74C\uC131 \uC785\uB825, \uD0C0\uC784\uB77C\uC778 \uBDF0", 6160)] }),
          new TableRow({ children: [cell("\u2461", 1400, { center: true }), cell("\uD328\uD134", 1800, { bold: true }), cell("\uC77C\uACFC\uD45C, \uC8FC\uAC04 \uD328\uD134, \uCE74\uD14C\uACE0\uB9AC\uBCC4 \uAC04\uACA9 \uBD84\uC11D", 6160)] }),
          new TableRow({ children: [cell("\u2462", 1400, { center: true }), cell("\uD1B5\uACC4", 1800, { bold: true }), cell("\uC218\uC720\uB7C9 \uBC14 \uCC28\uD2B8, \uC218\uBA74\uC2DC\uAC04 \uB77C\uC778 \uCC28\uD2B8, \uAE30\uAC04\uBCC4 \uC694\uC57D", 6160)] }),
          new TableRow({ children: [cell("\u2463", 1400, { center: true }), cell("\uD504\uB85C\uD544", 1800, { bold: true }), cell("\uC544\uAE30 \uC815\uBCF4, \uC131\uC7A5 \uBCF4\uACE0\uC11C, \uB9C8\uC77C\uC2A4\uD1A4, \uC131\uC7A5\uACE1\uC120, \uC721\uC544 \uC815\uBCF4", 6160)] }),
        ],
      }),

      new Paragraph({ children: [new PageBreak()] }),

      // ========== 2. 시작하기 ==========
      heading1("2. \uC2DC\uC791\uD558\uAE30 (\uCD08\uAE30 \uC124\uC815)"),
      body("\uC571\uC744 \uCC98\uC74C \uC2E4\uD589\uD558\uBA74 \uC544\uAE30 \uD504\uB85C\uD544 \uC124\uC815 \uD654\uBA74\uC774 \uB098\uD0C0\uB0A9\uB2C8\uB2E4."),
      spacer(60),

      heading2("2.1 \uD544\uC218 \uC785\uB825 \uD56D\uBAA9"),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [2400, 3000, 3960],
        rows: [
          new TableRow({ children: [headerCell("\uD56D\uBAA9", 2400), headerCell("\uC124\uBA85", 3000), headerCell("\uC608\uC2DC", 3960)] }),
          new TableRow({ children: [cell("\uC544\uAE30 \uC774\uB984 *", 2400, { bold: true }), cell("\uC544\uAE30\uC758 \uC774\uB984 \uB610\uB294 \uBCC4\uBA85", 3000), cell("\uD558\uC728\uC774", 3960)] }),
          new TableRow({ children: [cell("\uC0DD\uB144\uC6D4\uC77C *", 2400, { bold: true }), cell("\uC544\uAE30 \uC0DD\uB144\uC6D4\uC77C (\uB2EC\uB825 \uC120\uD0DD)", 3000), cell("2025\uB144 1\uC6D4 15\uC77C", 3960)] }),
        ],
      }),
      spacer(60),

      heading2("2.2 \uC120\uD0DD \uC785\uB825 \uD56D\uBAA9"),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [2400, 3000, 3960],
        rows: [
          new TableRow({ children: [headerCell("\uD56D\uBAA9", 2400), headerCell("\uC124\uBA85", 3000), headerCell("\uC608\uC2DC", 3960)] }),
          new TableRow({ children: [cell("\uC131\uBCC4", 2400), cell("\uB0A8\uC790 / \uC5EC\uC790", 3000), cell("\uD83D\uDC66 \uB0A8\uC790", 3960)] }),
          new TableRow({ children: [cell("\uCD9C\uC0DD \uCCB4\uC911 (kg)", 2400), cell("\uCD9C\uC0DD \uB2F9\uC2DC \uCCB4\uC911", 3000), cell("3.2", 3960)] }),
          new TableRow({ children: [cell("\uCD9C\uC0DD \uC2E0\uC7A5 (cm)", 2400), cell("\uCD9C\uC0DD \uB2F9\uC2DC \uD0A4", 3000), cell("50", 3960)] }),
        ],
      }),
      spacer(60),
      body("\uBAA8\uB4E0 \uD56D\uBAA9\uC744 \uC785\uB825\uD55C \uD6C4 \"\uC2DC\uC791\uD558\uAE30\" \uBC84\uD2BC\uC744 \uB204\uB974\uBA74 \uBA54\uC778 \uD654\uBA74\uC73C\uB85C \uC774\uB3D9\uD569\uB2C8\uB2E4."),
      tipBox("\uD83D\uDCA1 \uD301", "\uD504\uB85C\uD544\uC740 \uB098\uC911\uC5D0 \uD504\uB85C\uD544 \uD0ED\uC5D0\uC11C \uC5B8\uC81C\uB4E0 \uC218\uC815\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4."),

      new Paragraph({ children: [new PageBreak()] }),

      // ========== 3. 기록 화면 ==========
      heading1("3. \uAE30\uB85D \uD654\uBA74 (\uBA54\uC778)"),
      body("\uC571\uC758 \uCCAB \uBC88\uC9F8 \uD0ED\uC73C\uB85C, \uC721\uC544 \uAE30\uB85D\uC758 \uC785\uB825\uACFC \uC870\uD68C\uB97C \uBAA8\uB450 \uCC98\uB9AC\uD558\uB294 \uD575\uC2EC \uD654\uBA74\uC785\uB2C8\uB2E4."),
      spacer(60),

      heading2("3.1 \uCE74\uD14C\uACE0\uB9AC \uBE60\uB978 \uC785\uB825 (\uC544\uC774\uCF58 \uBC14)"),
      body("\uD654\uBA74 \uC0C1\uB2E8\uC758 12\uAC1C \uCE74\uD14C\uACE0\uB9AC \uC544\uC774\uCF58\uC744 \uD130\uCE58\uD558\uBA74 \uD574\uB2F9 \uAE30\uB85D\uC774 \uC989\uC2DC \uC0DD\uC131\uB429\uB2C8\uB2E4."),
      spacer(40),

      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [1560, 1560, 1560, 1560, 1560, 1560],
        rows: [
          new TableRow({ children: [headerCell("\uBAA8\uC720", 1560), headerCell("\uBD84\uC720", 1560), headerCell("\uC774\uC720\uC2DD", 1560), headerCell("\uAE30\uC800\uADC0", 1560), headerCell("\uC218\uBA74", 1560), headerCell("\uC720\uCD95", 1560)] }),
          new TableRow({ children: [headerCell("\uAC04\uC2DD", 1560), headerCell("\uCCB4\uC628", 1560), headerCell("\uC57D", 1560), headerCell("\uBAA9\uC695", 1560), headerCell("\uC678\uCD9C", 1560), headerCell("\uBCD1\uC6D0", 1560)] }),
        ],
      }),
      spacer(60),

      heading2("3.2 \uD14D\uC2A4\uD2B8 \uC785\uB825"),
      body("\uD654\uBA74 \uC6B0\uCE21 \uC0C1\uB2E8\uC758 + \uBC84\uD2BC \uB610\uB294 FAB(\uD558\uB2E8 + \uBC84\uD2BC)\uC744 \uB204\uB974\uBA74 \uD14D\uC2A4\uD2B8 \uC785\uB825\uCC3D\uC774 \uB098\uD0C0\uB0A9\uB2C8\uB2E4."),
      body("\uC608\uC2DC: \"\uBD84\uC720 120ml \uBA39\uC5C8\uC5B4\", \"\uC624\uD6C4 2\uC2DC\uC5D0 \uC7A4\uB4E4\uC5C8\uC5B4\", \"\uAE30\uC800\uADC0 \uC751\uAC00\"", { italic: true }),
      spacer(60),

      heading2("3.3 \uC74C\uC131 \uC785\uB825"),
      body("\uD654\uBA74 \uC6B0\uCE21 \uC0C1\uB2E8\uC758 \uB9C8\uC774\uD06C(\uD83C\uDFA4) \uC544\uC774\uCF58\uC744 \uB204\uB974\uBA74 \uC74C\uC131 \uC778\uC2DD\uC774 \uC2DC\uC791\uB429\uB2C8\uB2E4."),
      body("\uD55C\uAD6D\uC5B4\uB85C \uC790\uC5F0\uC2A4\uB7FD\uAC8C \uB9D0\uD558\uBA74 AI\uAC00 \uC790\uB3D9\uC73C\uB85C \uBD84\uC11D\uD558\uC5EC \uAE30\uB85D\uD569\uB2C8\uB2E4."),
      tipBox("\uD83D\uDCA1 \uD301", "\uC190\uC774 \uBC14\uC058 \uB54C \uC74C\uC131 \uC785\uB825\uC744 \uD65C\uC6A9\uD558\uC138\uC694! \uC544\uAE30\uB97C \uC548\uACE0 \uC788\uC744 \uB54C\uB3C4 \uD3B8\uB9AC\uD558\uAC8C \uAE30\uB85D\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4."),
      spacer(60),

      heading2("3.4 \uD0C0\uC784\uB77C\uC778 \uBDF0"),
      body("\uAE30\uB85D\uB4E4\uC774 \uB0A0\uC9DC\uBCC4(\uC624\uB298/\uC5B4\uC81C/\uADF8\uC800\uAED8)\uB85C \uADF8\uB8F9\uD654\uB418\uC5B4 \uD45C\uC2DC\uB429\uB2C8\uB2E4."),
      new Paragraph({ numbering: { reference: "bullets2", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uAC01 \uAE30\uB85D\uC740 \uC2DC\uAC04, \uCE74\uD14C\uACE0\uB9AC \uC0C9\uC0C1 \uC810, \uC81C\uBAA9, \uC138\uBD80\uC815\uBCF4\uB97C \uD45C\uC2DC\uD569\uB2C8\uB2E4", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "bullets2", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uAE30\uB85D\uC744 \uD130\uCE58\uD558\uBA74 \uC0C1\uC138 \uD654\uBA74\uC73C\uB85C \uC774\uB3D9\uD558\uC5EC \uC218\uC815/\uC0AD\uC81C\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "bullets2", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uB0A0\uC9DC \uD5E4\uB354\uC5D0 \uD574\uB2F9\uC77C \uCD1D \uC218\uC720\uB7C9(ml)\uACFC D+ \uC77C\uC218\uAC00 \uD45C\uC2DC\uB429\uB2C8\uB2E4", font: "Arial", size: 22 })] }),
      spacer(60),

      heading2("3.5 \uB9C8\uC9C0\uB9C9 \uAE30\uB85D \uC694\uC57D"),
      body("\uD654\uBA74 \uC0C1\uB2E8\uC5D0 3\uAC1C\uC758 \uC694\uC57D \uCE74\uB4DC\uAC00 \uD45C\uC2DC\uB429\uB2C8\uB2E4:"),
      new Paragraph({ numbering: { reference: "numbers", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uB9C8\uC9C0\uB9C9 \uAE30\uC800\uADC0: \uACBD\uACFC \uC2DC\uAC04 + \uC885\uB958(\uC18C\uBCC0/\uB300\uBCC0)", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "numbers", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uB9C8\uC9C0\uB9C9 \uC218\uC720: \uACBD\uACFC \uC2DC\uAC04 + \uC218\uC720\uB7C9(ml)", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "numbers", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uB9C8\uC9C0\uB9C9 \uC218\uBA74: \uACBD\uACFC \uC2DC\uAC04 + \uC0C1\uD0DC(\uC218\uBA74\uC911/\uAE4A\uC5B4\uB0A8)", font: "Arial", size: 22 })] }),

      new Paragraph({ children: [new PageBreak()] }),

      // ========== 4. 자연어 입력 가이드 ==========
      heading1("4. \uC790\uC5F0\uC5B4 \uC785\uB825 \uAC00\uC774\uB4DC"),
      body("ChatBabyTime\uC758 \uD575\uC2EC \uAE30\uB2A5\uC785\uB2C8\uB2E4. \uD55C\uAD6D\uC5B4\uB85C \uC790\uC5F0\uC2A4\uB7FD\uAC8C \uC785\uB825\uD558\uBA74 AI\uAC00 \uCE74\uD14C\uACE0\uB9AC, \uC591, \uC2DC\uAC04 \uB4F1\uC744 \uC790\uB3D9 \uBD84\uC11D\uD569\uB2C8\uB2E4."),
      spacer(60),

      heading2("4.1 \uC218\uC720 \uAE30\uB85D"),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [4680, 4680],
        rows: [
          new TableRow({ children: [headerCell("\uC785\uB825 \uC608\uC2DC", 4680), headerCell("\uC778\uC2DD \uACB0\uACFC", 4680)] }),
          new TableRow({ children: [cell("\"\uBD84\uC720 120ml \uBA39\uC5C8\uC5B4\"", 4680), cell("\uBD84\uC720 120ml, \uD604\uC7AC \uC2DC\uAC04", 4680)] }),
          new TableRow({ children: [cell("\"\uBAA8\uC720 \uC218\uC720 15\uBD84\"", 4680), cell("\uBAA8\uC720 15\uBD84\uAC04, \uD604\uC7AC \uC2DC\uAC04", 4680)] }),
          new TableRow({ children: [cell("\"\uC624\uD6C4 2\uC2DC 30\uBD84\uC5D0 \uC774\uC720\uC2DD\"", 4680), cell("\uC774\uC720\uC2DD, \uC624\uD6C4 2:30", 4680)] }),
          new TableRow({ children: [cell("\"\uAC04\uC2DD \uBA39\uC74C\"", 4680), cell("\uAC04\uC2DD, \uD604\uC7AC \uC2DC\uAC04", 4680)] }),
          new TableRow({ children: [cell("\"3\uC2DC\uAC04 \uC804 \uC720\uCD95\"", 4680), cell("\uBAA8\uC720(\uC720\uCD95), 3\uC2DC\uAC04 \uC804", 4680)] }),
        ],
      }),
      spacer(60),

      heading2("4.2 \uC218\uBA74 \uAE30\uB85D"),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [4680, 4680],
        rows: [
          new TableRow({ children: [headerCell("\uC785\uB825 \uC608\uC2DC", 4680), headerCell("\uC778\uC2DD \uACB0\uACFC", 4680)] }),
          new TableRow({ children: [cell("\"\uC7A0\uB4E4\uC5C8\uC5B4\"", 4680), cell("\uC7A0\uB4E6 \uAE30\uB85D, \uD604\uC7AC \uC2DC\uAC04", 4680)] }),
          new TableRow({ children: [cell("\"\uC544\uCE68 7\uC2DC\uC5D0 \uAE5C\uC5B4\"", 4680), cell("\uAE68\uC5B4\uB0A8 \uAE30\uB85D, \uC624\uC804 7:00", 4680)] }),
          new TableRow({ children: [cell("\"30\uBD84 \uB9CC\uC5D0 \uAE5C\uC5C8\uC5B4\"", 4680), cell("\uAE68\uC5B4\uB0A8, 30\uBD84 \uC804", 4680)] }),
          new TableRow({ children: [cell("\"\uB0AE\uC7A0 \uC7A4\uC5B4\"", 4680), cell("\uC7A0\uB4E6 \uAE30\uB85D, \uD604\uC7AC \uC2DC\uAC04", 4680)] }),
        ],
      }),
      spacer(60),

      heading2("4.3 \uAE30\uC800\uADC0 \uAE30\uB85D"),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [4680, 4680],
        rows: [
          new TableRow({ children: [headerCell("\uC785\uB825 \uC608\uC2DC", 4680), headerCell("\uC778\uC2DD \uACB0\uACFC", 4680)] }),
          new TableRow({ children: [cell("\"\uAE30\uC800\uADC0 \uAC08\uC558\uC5B4\"", 4680), cell("\uC18C\uBCC0, \uD604\uC7AC \uC2DC\uAC04", 4680)] }),
          new TableRow({ children: [cell("\"\uAE30\uC800\uADC0 \uC751\uAC00\"", 4680), cell("\uB300\uBCC0, \uD604\uC7AC \uC2DC\uAC04", 4680)] }),
          new TableRow({ children: [cell("\"\uC18C\uBCC0 \uB300\uBCC0\"", 4680), cell("\uC18C\uBCC0+\uB300\uBCC0, \uD604\uC7AC \uC2DC\uAC04", 4680)] }),
        ],
      }),
      spacer(60),

      heading2("4.4 \uAC74\uAC15 \uAE30\uB85D"),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [4680, 4680],
        rows: [
          new TableRow({ children: [headerCell("\uC785\uB825 \uC608\uC2DC", 4680), headerCell("\uC778\uC2DD \uACB0\uACFC", 4680)] }),
          new TableRow({ children: [cell("\"\uCCB4\uC628 37.5\uB3C4\"", 4680), cell("\uCCB4\uC628 37.5\u00B0C \uAE30\uB85D", 4680)] }),
          new TableRow({ children: [cell("\"\uC57D \uD0C0\uC774\uB808\uB180\"", 4680), cell("\uC57D \uBCF5\uC6A9 \"\uD0C0\uC774\uB808\uB180\" \uAE30\uB85D", 4680)] }),
          new TableRow({ children: [cell("\"\uC608\uBC29\uC811\uC885 \uB9DE\uC558\uC5B4\"", 4680), cell("\uAC74\uAC15 \uAE30\uB85D", 4680)] }),
        ],
      }),
      spacer(60),

      heading2("4.5 \uC2DC\uAC04 \uC785\uB825 \uBC29\uBC95"),
      body("\uC2DC\uAC04\uC744 \uBA85\uC2DC\uD558\uC9C0 \uC54A\uC73C\uBA74 \uD604\uC7AC \uC2DC\uAC04\uC73C\uB85C \uAE30\uB85D\uB429\uB2C8\uB2E4. \uB2E4\uC591\uD55C \uC2DC\uAC04 \uD45C\uD604\uC744 \uC9C0\uC6D0\uD569\uB2C8\uB2E4:"),
      spacer(40),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [3120, 3120, 3120],
        rows: [
          new TableRow({ children: [headerCell("\uD45C\uD604", 3120), headerCell("\uC608\uC2DC", 3120), headerCell("\uACB0\uACFC", 3120)] }),
          new TableRow({ children: [cell("\uC0DD\uB7B5 (\uD604\uC7AC)", 3120), cell("\"\uBA39\uC5C8\uC5B4\"", 3120), cell("\uD604\uC7AC \uC2DC\uAC04", 3120)] }),
          new TableRow({ children: [cell("\"\uBC29\uAE08\" / \"\uC9C0\uAE08\"", 3120), cell("\"\uBC29\uAE08 \uBA39\uC5C8\uC5B4\"", 3120), cell("\uD604\uC7AC \uC2DC\uAC04", 3120)] }),
          new TableRow({ children: [cell("\"N\uBD84 \uC804\"", 3120), cell("\"10\uBD84 \uC804\"", 3120), cell("10\uBD84 \uC804", 3120)] }),
          new TableRow({ children: [cell("\"N\uC2DC\uAC04 \uC804\"", 3120), cell("\"2\uC2DC\uAC04 \uC804\"", 3120), cell("2\uC2DC\uAC04 \uC804", 3120)] }),
          new TableRow({ children: [cell("\"\uC624\uC804/\uC624\uD6C4 N\uC2DC\"", 3120), cell("\"\uC624\uD6C4 2\uC2DC 30\uBD84\"", 3120), cell("14:30", 3120)] }),
          new TableRow({ children: [cell("\"\uC544\uCE68/\uC800\uB141/\uBC24\"", 3120), cell("\"\uC544\uCE68 8\uC2DC\"", 3120), cell("08:00", 3120)] }),
          new TableRow({ children: [cell("\"N\uC2DC\" (\uC790\uB3D9 \uCD94\uB860)", 3120), cell("\"\uD604\uC7AC 15\uC2DC\uC77C \uB54C 2\uC2DC\"", 3120), cell("14:00 (\uAC00\uC7A5 \uAC00\uAE4C\uC6B4 \uACFC\uAC70)", 3120)] }),
        ],
      }),
      spacer(60),
      tipBox("\uD83D\uDCA1 \uC2A4\uB9C8\uD2B8 \uC2DC\uAC04 \uCD94\uB860", "\"\uD604\uC7AC \uC624\uD6C4 3\uC2DC\uC77C \uB54C \"2\uC2DC\uC5D0 \uC7A4\uC5B4\"\uB77C\uACE0 \uC785\uB825\uD558\uBA74, \uC624\uC804 2\uC2DC\uBCF4\uB2E4 \uC624\uD6C4 2\uC2DC\uAC00 \uD604\uC7AC\uC5D0 \uB354 \uAC00\uAE4C\uC6B0\uBBC0\uB85C \uC790\uB3D9\uC73C\uB85C \uC624\uD6C4 2\uC2DC\uB85C \uC778\uC2DD\uD569\uB2C8\uB2E4."),

      new Paragraph({ children: [new PageBreak()] }),

      // ========== 5. 기록 상세/수정 ==========
      heading1("5. \uAE30\uB85D \uC0C1\uC138 \uBC0F \uC218\uC815"),
      body("\uD0C0\uC784\uB77C\uC778\uC5D0\uC11C \uAE30\uB85D\uC744 \uD130\uCE58\uD558\uBA74 \uC0C1\uC138 \uD654\uBA74\uC73C\uB85C \uC774\uB3D9\uD569\uB2C8\uB2E4."),
      spacer(60),

      heading2("5.1 \uC218\uC815 \uAC00\uB2A5 \uD56D\uBAA9"),
      new Paragraph({ numbering: { reference: "numbers2", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uC2DC\uAC04: \uC2DC\uAC04 \uC120\uD0DD\uAE30\uB85C \uBCC0\uACBD", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "numbers2", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uCE74\uD14C\uACE0\uB9AC: \uC218\uC720/\uC218\uBA74/\uAE30\uC800\uADC0/\uAC74\uAC15/\uAE30\uD0C0 \uBCC0\uACBD", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "numbers2", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uCE74\uD14C\uACE0\uB9AC\uBCC4 \uC0C1\uC138: \uC218\uC720 \uC885\uB958/\uC591/\uC2DC\uAC04, \uC218\uBA74 \uC0C1\uD0DC, \uAE30\uC800\uADC0 \uC885\uB958, \uCCB4\uC628/\uC57D", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "numbers2", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uBA54\uBAA8: \uCD94\uAC00 \uBA54\uBAA8 \uC785\uB825", font: "Arial", size: 22 })] }),
      spacer(60),

      heading2("5.2 \uC0AD\uC81C"),
      body("\uC0C1\uC138 \uD654\uBA74 \uC6B0\uCE21 \uC0C1\uB2E8\uC758 \uD734\uC9C0\uD1B5(\uD83D\uDDD1) \uC544\uC774\uCF58\uC744 \uB204\uB974\uBA74 \uAE30\uB85D\uC774 \uC0AD\uC81C\uB429\uB2C8\uB2E4."),
      body("\uC0AD\uC81C\uB41C \uAE30\uB85D\uC740 \uBCF5\uAD6C\uD560 \uC218 \uC5C6\uC73C\uB2C8 \uC8FC\uC758\uD558\uC138\uC694.", { italic: true }),

      new Paragraph({ children: [new PageBreak()] }),

      // ========== 6. 패턴 화면 ==========
      heading1("6. \uD328\uD134 \uD654\uBA74"),
      body("\uB450 \uBC88\uC9F8 \uD0ED\uC73C\uB85C, \uAE30\uB85D\uB41C \uB370\uC774\uD130\uC758 \uD328\uD134\uC744 3\uAC00\uC9C0 \uBC29\uC2DD\uC73C\uB85C \uBD84\uC11D\uD569\uB2C8\uB2E4."),
      spacer(60),

      heading2("6.1 \uC77C\uACFC\uD45C"),
      body("\uC624\uB298\uC758 \uBAA8\uB4E0 \uAE30\uB85D\uC744 \uC2DC\uAC04\uC21C\uC73C\uB85C \uD0C0\uC784\uB77C\uC778 \uD615\uD0DC\uB85C \uD45C\uC2DC\uD569\uB2C8\uB2E4. \uAC00\uC7A5 \uCD5C\uADFC \uAE30\uB85D\uC740 \uAC15\uC870 \uD45C\uC2DC\uB429\uB2C8\uB2E4."),
      spacer(40),

      heading2("6.2 \uC8FC\uAC04 \uD328\uD134"),
      body("\uCD5C\uADFC 7\uC77C\uAC04\uC758 \uAE30\uB85D\uC744 \uC694\uC77C\uBCC4\uB85C \uADF8\uB8F9\uD654\uD558\uC5EC \uBCF4\uC5EC\uC90D\uB2C8\uB2E4. \uAC01 \uC694\uC77C\uC758 \uAE30\uB85D \uD56D\uBAA9\uACFC \uC2DC\uAC04\uC744 \uD55C\uB208\uC5D0 \uD655\uC778\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4."),
      spacer(40),

      heading2("6.3 \uAC04\uACA9 \uD328\uD134"),
      body("\uC120\uD0DD\uD55C \uCE74\uD14C\uACE0\uB9AC(\uC774\uC720\uC2DD, \uD22C\uC57D, \uC218\uBA74, \uBC30\uBCC0, \uBAA9\uC695)\uC758 \uAE30\uB85D\uB4E4 \uC0AC\uC774 \uC2DC\uAC04 \uAC04\uACA9\uC744 \uBD84\uC11D\uD569\uB2C8\uB2E4."),
      body("\uD558\uB2E8\uC5D0 \uD3C9\uADE0 \uAC04\uACA9\uACFC \uD568\uAED8 \uC778\uC0AC\uC774\uD2B8 \uCE74\uB4DC\uAC00 \uD45C\uC2DC\uB429\uB2C8\uB2E4:"),
      new Paragraph({ numbering: { reference: "numbers3", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uC218\uC720: \"\uADDC\uCE59\uC801\uC778 \uC2DD\uC0AC \uD328\uD134\uC774 \uD615\uC131\uB418\uACE0 \uC788\uC2B5\uB2C8\uB2E4\" (\uD3C9\uADE0 3\uC2DC\uAC04 \uC774\uC0C1\uC77C \uB54C)", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "numbers3", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uC218\uBA74: \"\uC218\uBA74 \uD328\uD134\uC744 \uBAA8\uB2C8\uD130\uB9C1 \uC911\uC785\uB2C8\uB2E4\"", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "numbers3", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uAE30\uC800\uADC0: \"\uBC30\uBCC0 \uD328\uD134\uC744 \uAE30\uB85D\uD558\uACE0 \uC788\uC2B5\uB2C8\uB2E4\"", font: "Arial", size: 22 })] }),

      new Paragraph({ children: [new PageBreak()] }),

      // ========== 7. 통계 화면 ==========
      heading1("7. \uD1B5\uACC4 \uD654\uBA74"),
      body("\uC138 \uBC88\uC9F8 \uD0ED\uC73C\uB85C, \uAE30\uAC04\uBCC4 \uC218\uC720\uB7C9, \uC218\uBA74\uC2DC\uAC04 \uB4F1\uC744 \uCC28\uD2B8\uB85C \uC2DC\uAC01\uD654\uD569\uB2C8\uB2E4."),
      spacer(60),

      heading2("7.1 \uAE30\uAC04 \uC120\uD0DD"),
      body("\uC0C1\uB2E8\uC758 3\uAC1C \uBC84\uD2BC\uC73C\uB85C \uAE30\uAC04\uC744 \uC120\uD0DD\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4:"),
      new Paragraph({ numbering: { reference: "numbers4", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uC77C: \uC624\uB298 \uD558\uB8E8 \uD1B5\uACC4", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "numbers4", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uC8FC: \uCD5C\uADFC 7\uC77C \uD1B5\uACC4 (\uAE30\uBCF8\uAC12)", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "numbers4", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uC6D4: \uCD5C\uADFC 30\uC77C \uD1B5\uACC4", font: "Arial", size: 22 })] }),
      spacer(40),

      heading2("7.2 \uCC28\uD2B8 \uC885\uB958"),
      body("\uC218\uC720\uB7C9 \uBC14 \uCC28\uD2B8: \uAE30\uAC04 \uB0B4 \uC77C\uBCC4 \uC218\uC720\uB7C9(ml)\uC744 \uB9C9\uB300 \uADF8\uB798\uD504\uB85C \uD45C\uC2DC\uD569\uB2C8\uB2E4."),
      body("\uC218\uBA74\uC2DC\uAC04 \uB77C\uC778 \uCC28\uD2B8: \uAE30\uAC04 \uB0B4 \uC77C\uBCC4 \uC218\uBA74\uC2DC\uAC04\uC744 \uAF2D\uC740\uC120 \uADF8\uB798\uD504\uB85C \uD45C\uC2DC\uD569\uB2C8\uB2E4."),
      body("\uC694\uC57D \uD1B5\uACC4: \uCD1D \uC218\uC720 \uD69F\uC218, \uD3C9\uADE0 \uCDE8\uCE68 \uC2DC\uAC01, \uC774\uC804 \uAE30\uAC04 \uB300\uBE44 \uD2B8\uB80C\uB4DC \uBE44\uAD50\uB97C \uBCF4\uC5EC\uC90D\uB2C8\uB2E4."),

      new Paragraph({ children: [new PageBreak()] }),

      // ========== 8. 프로필 화면 ==========
      heading1("8. \uD504\uB85C\uD544 \uD654\uBA74"),
      body("\uB124 \uBC88\uC9F8 \uD0ED\uC73C\uB85C, \uC544\uAE30 \uC815\uBCF4 \uD655\uC778\uACFC \uBD80\uAC00 \uAE30\uB2A5\uC744 \uC81C\uACF5\uD569\uB2C8\uB2E4."),
      spacer(60),

      heading2("8.1 \uC544\uAE30 \uC815\uBCF4 \uCE74\uB4DC"),
      body("\uC544\uAE30 \uC774\uB984, D+ \uC77C\uC218, \uC8FC/\uC77C \uB098\uC774, \uD504\uB85C\uD544 \uC0AC\uC9C4\uC774 \uD45C\uC2DC\uB429\uB2C8\uB2E4."),
      spacer(40),

      heading2("8.2 \uBD80\uAC00 \uAE30\uB2A5 (4\uAC1C)"),
      spacer(20),

      heading3("\u2460 \uC131\uC7A5 \uBD84\uC11D \uBCF4\uACE0\uC11C"),
      body("\uCD5C\uADFC 7\uC77C\uAC04\uC758 \uC218\uC720/\uAE30\uC800\uADC0/\uC218\uBA74 \uD1B5\uACC4\uC640 AI \uC778\uC0AC\uC774\uD2B8\uB97C \uC81C\uACF5\uD569\uB2C8\uB2E4."),
      body("\uC608: \"\uC774\uBC88 \uC8FC \uC218\uC720 \uD328\uD134\uC774 \uC548\uC815\uC801\uC785\uB2C8\uB2E4\", \"\uC218\uC720\uB7C9\uC774 \uC801\uC815 \uBC94\uC704 \uB0B4\uC785\uB2C8\uB2E4\"", { italic: true }),
      spacer(20),

      heading3("\u2461 \uB9C8\uC77C\uC2A4\uD1A4"),
      body("\uC6D4\uB839\uBCC4 \uBC1C\uB2EC \uCCB4\uD06C\uB9AC\uC2A4\uD2B8\uC785\uB2C8\uB2E4. 0-3\uAC1C\uC6D4, 3-6\uAC1C\uC6D4, 6-9\uAC1C\uC6D4, 9-12\uAC1C\uC6D4 \uADF8\uB8F9\uBCC4\uB85C \uBC1C\uB2EC \uD56D\uBAA9\uC744 \uCCB4\uD06C\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4."),
      body("\uC608\uC2DC \uD56D\uBAA9: \uACE0\uAC1C \uB4E4\uAE30, \uB4A4\uC9D1\uAE30, \uC639\uC54C\uC774, \uC549\uAE30, \uAE30\uC5B4\uB2E4\uB2C8\uAE30, \uCCAB \uC774, \uAC77\uAE30, \uCCAB \uB2E8\uC5B4", { italic: true }),
      spacer(20),

      heading3("\u2462 \uC131\uC7A5\uACE1\uC120"),
      body("\uD0A4\uC640 \uBAB8\uBB34\uAC8C\uB97C \uC785\uB825\uD558\uBA74 WHO \uD45C\uC900 \uC131\uC7A5\uACE1\uC120\uACFC \uBE44\uAD50\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4. \uC6D4\uB839\uBCC4 \uD3C9\uADE0 \uD0A4/\uBAB8\uBB34\uAC8C\uC640 \uC815\uC0C1 \uBC94\uC704\uAC00 \uD45C\uC2DC\uB429\uB2C8\uB2E4."),
      spacer(20),

      heading3("\u2463 \uC721\uC544 \uC815\uBCF4"),
      body("\uC544\uAE30 \uC6D4\uB839\uC5D0 \uB9DE\uB294 \uB9DE\uCDA4 \uC721\uC544 \uAC00\uC774\uB4DC\uB97C \uC81C\uACF5\uD569\uB2C8\uB2E4. \uC218\uC720 \uAC00\uC774\uB4DC, \uC218\uBA74 \uAD50\uC721, \uC774\uC720\uC2DD \uC2DC\uC791, \uC608\uBC29\uC811\uC885 \uC77C\uC815 \uB4F1\uC758 \uC815\uBCF4\uAC00 \uD3BC\uCE58\uAE30 \uCE74\uB4DC\uB85C \uD45C\uC2DC\uB429\uB2C8\uB2E4."),

      new Paragraph({ children: [new PageBreak()] }),

      // ========== 9. 카테고리별 색상 안내 ==========
      heading1("9. \uCE74\uD14C\uACE0\uB9AC\uBCC4 \uC0C9\uC0C1 \uC548\uB0B4"),
      body("\uD0C0\uC784\uB77C\uC778\uACFC \uCC28\uD2B8\uC5D0\uC11C \uCE74\uD14C\uACE0\uB9AC\uB97C \uBE60\uB974\uAC8C \uAD6C\uBD84\uD560 \uC218 \uC788\uB3C4\uB85D \uC0C9\uC0C1\uC774 \uC9C0\uC815\uB418\uC5B4 \uC788\uC2B5\uB2C8\uB2E4:"),
      spacer(40),

      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [2340, 2340, 2340, 2340],
        rows: [
          new TableRow({ children: [headerCell("\uCE74\uD14C\uACE0\uB9AC", 2340), headerCell("\uC0C9\uC0C1", 2340), headerCell("\uC544\uC774\uCF58", 2340), headerCell("\uC6A9\uB3C4", 2340)] }),
          new TableRow({ children: [
            cell("\uC218\uC720", 2340, { bold: true }),
            new TableCell({ borders, width: { size: 2340, type: WidthType.DXA }, margins: cellMargin, shading: { fill: "E8FFF5", type: ShadingType.CLEAR },
              children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "\u25CF \uBBFC\uD2B8 \uADF8\uB9B0", font: "Arial", size: 20, color: "46F1C5" })] })] }),
            cell("\uD83C\uDF7C", 2340, { center: true }),
            cell("\uBAA8\uC720/\uBD84\uC720/\uC774\uC720\uC2DD/\uAC04\uC2DD", 2340),
          ] }),
          new TableRow({ children: [
            cell("\uC218\uBA74", 2340, { bold: true }),
            new TableCell({ borders, width: { size: 2340, type: WidthType.DXA }, margins: cellMargin, shading: { fill: "EEEDF8", type: ShadingType.CLEAR },
              children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "\u25CF \uBCF4\uB77C", font: "Arial", size: 20, color: "C5C4E2" })] })] }),
            cell("\uD83D\uDE34", 2340, { center: true }),
            cell("\uC7A0\uB4E6/\uAE68\uC5B4\uB0A8", 2340),
          ] }),
          new TableRow({ children: [
            cell("\uAE30\uC800\uADC0", 2340, { bold: true }),
            new TableCell({ borders, width: { size: 2340, type: WidthType.DXA }, margins: cellMargin, shading: { fill: "FFF8E8", type: ShadingType.CLEAR },
              children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "\u25CF \uC624\uB80C\uC9C0", font: "Arial", size: 20, color: "FFD268" })] })] }),
            cell("\uD83E\uDDF7", 2340, { center: true }),
            cell("\uC18C\uBCC0/\uB300\uBCC0", 2340),
          ] }),
          new TableRow({ children: [
            cell("\uAC74\uAC15", 2340, { bold: true }),
            new TableCell({ borders, width: { size: 2340, type: WidthType.DXA }, margins: cellMargin, shading: { fill: "E8F8F2", type: ShadingType.CLEAR },
              children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "\u25CF \uCCAD\uB85D", font: "Arial", size: 20, color: "AEE8D8" })] })] }),
            cell("\uD83C\uDF21\uFE0F", 2340, { center: true }),
            cell("\uCCB4\uC628/\uC57D/\uBCD1\uC6D0", 2340),
          ] }),
        ],
      }),

      spacer(200),

      // ========== 10. 데이터 저장 ==========
      heading1("10. \uB370\uC774\uD130 \uC800\uC7A5 \uC548\uB0B4"),
      body("\uBAA8\uB4E0 \uB370\uC774\uD130\uB294 \uAE30\uAE30 \uB0B4\uBD80(Hive \uB85C\uCEEC \uB370\uC774\uD130\uBCA0\uC774\uC2A4)\uC5D0 \uC800\uC7A5\uB429\uB2C8\uB2E4."),
      new Paragraph({ numbering: { reference: "numbers5", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uC778\uD130\uB137 \uC5F0\uACB0 \uC5C6\uC774 \uC0AC\uC6A9 \uAC00\uB2A5\uD569\uB2C8\uB2E4", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "numbers5", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uAC1C\uC778\uC815\uBCF4\uAC00 \uC678\uBD80 \uC11C\uBC84\uB85C \uC804\uC1A1\uB418\uC9C0 \uC54A\uC2B5\uB2C8\uB2E4", font: "Arial", size: 22 })] }),
      new Paragraph({ numbering: { reference: "numbers5", level: 0 }, spacing: { after: 80 }, children: [new TextRun({ text: "\uC571\uC744 \uC0AD\uC81C\uD558\uBA74 \uBAA8\uB4E0 \uB370\uC774\uD130\uAC00 \uD568\uAED8 \uC0AD\uC81C\uB429\uB2C8\uB2E4", font: "Arial", size: 22 })] }),
      spacer(40),
      tipBox("\u26A0\uFE0F \uC8FC\uC758", "\uC571\uC744 \uC0AD\uC81C\uD558\uAE30 \uC804\uC5D0 \uC911\uC694\uD55C \uAE30\uB85D\uC744 \uBC31\uC5C5\uD574\uB450\uC138\uC694. \uC0AD\uC81C\uB41C \uB370\uC774\uD130\uB294 \uBCF5\uAD6C\uD560 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4."),

      spacer(300),

      // ========== Footer ==========
      new Paragraph({
        alignment: AlignmentType.CENTER,
        border: { top: { style: BorderStyle.SINGLE, size: 2, color: MINT, space: 8 } },
        spacing: { before: 200 },
        children: [new TextRun({ text: "ChatBabyTime v1.0 | \uD55C\uAD6D\uC5B4 AI \uC721\uC544 \uAE30\uB85D \uC571", font: "Arial", size: 18, color: "999999" })],
      }),
    ],
  }],
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("/sessions/elegant-eager-pasteur/mnt/ChatBabyTime/ChatBabyTime_사용설명서.docx", buffer);
  console.log("Document created successfully!");
});

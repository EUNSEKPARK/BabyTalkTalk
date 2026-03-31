const fs = require("fs");
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
        Header, Footer, AlignmentType, HeadingLevel, BorderStyle, WidthType,
        ShadingType, PageNumber, PageBreak, LevelFormat } = require("docx");

const mint = "2DB89A";
const darkMint = "1A8A72";
const navy = "1E1E32";
const lightGray = "F5F5F5";
const medGray = "E8E8E8";
const accentOrange = "F5A623";
const accentRed = "E74C3C";
const accentGreen = "27AE60";
const accentBlue = "3498DB";
const white = "FFFFFF";

const border = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" };
const borders = { top: border, bottom: border, left: border, right: border };
const noBorder = { style: BorderStyle.NONE, size: 0 };
const noBorders = { top: noBorder, bottom: noBorder, left: noBorder, right: noBorder };
const cellMargins = { top: 80, bottom: 80, left: 120, right: 120 };

function heading(text, level = HeadingLevel.HEADING_1) {
  return new Paragraph({ heading: level, spacing: { before: 300, after: 200 }, children: [new TextRun({ text, bold: true, color: level === HeadingLevel.HEADING_1 ? navy : darkMint })] });
}

function h2(text) { return heading(text, HeadingLevel.HEADING_2); }
function h3(text) { return heading(text, HeadingLevel.HEADING_3); }

function para(text, opts = {}) {
  return new Paragraph({ spacing: { after: 120 }, ...opts, children: [new TextRun({ text, size: 22, ...opts.run })] });
}

function boldPara(label, text) {
  return new Paragraph({ spacing: { after: 100 }, children: [
    new TextRun({ text: label, bold: true, size: 22 }),
    new TextRun({ text, size: 22 }),
  ]});
}

function bulletItem(text, ref = "bullets", level = 0) {
  return new Paragraph({ numbering: { reference: ref, level }, spacing: { after: 80 }, children: [new TextRun({ text, size: 22 })] });
}

function richBullet(boldText, normalText, ref = "bullets") {
  return new Paragraph({ numbering: { reference: ref, level: 0 }, spacing: { after: 80 }, children: [
    new TextRun({ text: boldText, bold: true, size: 22 }),
    new TextRun({ text: normalText, size: 22 }),
  ]});
}

function ratingBar(score, max = 10) {
  const filled = "★".repeat(score);
  const empty = "☆".repeat(max - score);
  return `${filled}${empty} ${score}/${max}`;
}

function scoreCell(score, label, color) {
  return new TableCell({
    borders: noBorders, width: { size: 2340, type: WidthType.DXA },
    shading: { fill: color, type: ShadingType.CLEAR },
    margins: { top: 120, bottom: 120, left: 100, right: 100 },
    children: [
      new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: `${score}`, size: 48, bold: true, color: white })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 40 }, children: [new TextRun({ text: label, size: 18, color: white })] }),
    ]
  });
}

function headerCell(text, width) {
  return new TableCell({
    borders, width: { size: width, type: WidthType.DXA },
    shading: { fill: navy, type: ShadingType.CLEAR },
    margins: cellMargins,
    children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text, bold: true, size: 20, color: white })] })]
  });
}

function cell(text, width, opts = {}) {
  return new TableCell({
    borders, width: { size: width, type: WidthType.DXA },
    shading: opts.fill ? { fill: opts.fill, type: ShadingType.CLEAR } : undefined,
    margins: cellMargins,
    children: [new Paragraph({ alignment: opts.align || AlignmentType.LEFT, children: [
      new TextRun({ text, size: 20, bold: opts.bold || false, color: opts.color || "333333" })
    ] })]
  });
}

function infoBox(title, content, fillColor = "E8F6F3") {
  return new Table({
    width: { size: 9360, type: WidthType.DXA }, columnWidths: [9360],
    rows: [new TableRow({ children: [new TableCell({
      borders: { top: { style: BorderStyle.SINGLE, size: 6, color: mint }, bottom: noBorder, left: { style: BorderStyle.SINGLE, size: 6, color: mint }, right: noBorder },
      width: { size: 9360, type: WidthType.DXA },
      shading: { fill: fillColor, type: ShadingType.CLEAR },
      margins: { top: 120, bottom: 120, left: 200, right: 200 },
      children: [
        new Paragraph({ spacing: { after: 60 }, children: [new TextRun({ text: title, bold: true, size: 22, color: darkMint })] }),
        new Paragraph({ children: [new TextRun({ text: content, size: 20 })] }),
      ]
    })] })]
  });
}

function spacer(size = 200) {
  return new Paragraph({ spacing: { after: size }, children: [] });
}

// ========== BUILD DOCUMENT ==========
const doc = new Document({
  styles: {
    default: { document: { run: { font: "Arial", size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 36, bold: true, font: "Arial", color: navy },
        paragraph: { spacing: { before: 360, after: 240 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 30, bold: true, font: "Arial", color: darkMint },
        paragraph: { spacing: { before: 280, after: 180 }, outlineLevel: 1 } },
      { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 26, bold: true, font: "Arial", color: "444444" },
        paragraph: { spacing: { before: 200, after: 120 }, outlineLevel: 2 } },
    ]
  },
  numbering: {
    config: [
      { reference: "bullets", levels: [
        { level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
        { level: 1, format: LevelFormat.BULLET, text: "\u25E6", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 1440, hanging: 360 } } } },
      ]},
      { reference: "numbers", levels: [
        { level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
      ]},
      { reference: "phase1", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
      { reference: "phase2", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
      { reference: "phase3", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    ]
  },
  sections: [
    // ===== COVER PAGE =====
    {
      properties: {
        page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } }
      },
      children: [
        spacer(1600),
        new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 }, children: [
          new TextRun({ text: "ChatBabyTime", size: 72, bold: true, color: mint }),
        ]}),
        new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 100 }, children: [
          new TextRun({ text: "Google Play Store", size: 36, color: navy }),
        ]}),
        new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 600 }, children: [
          new TextRun({ text: "Commercial Viability Assessment", size: 36, color: navy }),
          new TextRun({ text: " & Improvement Roadmap", size: 36, color: darkMint }),
        ]}),
        new Table({
          width: { size: 5000, type: WidthType.DXA }, columnWidths: [5000],
          rows: [new TableRow({ children: [new TableCell({
            borders: { top: { style: BorderStyle.SINGLE, size: 3, color: mint }, bottom: noBorder, left: noBorder, right: noBorder },
            width: { size: 5000, type: WidthType.DXA },
            children: [new Paragraph({ text: "" })]
          })] })]
        }),
        spacer(200),
        new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 80 }, children: [
          new TextRun({ text: "2026.03.22", size: 24, color: "666666" }),
        ]}),
        new Paragraph({ alignment: AlignmentType.CENTER, children: [
          new TextRun({ text: "Prepared for PARK EUN", size: 24, color: "666666" }),
        ]}),
        new PageBreak(),
      ]
    },

    // ===== MAIN CONTENT =====
    {
      properties: {
        page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } }
      },
      headers: {
        default: new Header({ children: [new Paragraph({
          border: { bottom: { style: BorderStyle.SINGLE, size: 1, color: mint, space: 4 } },
          children: [new TextRun({ text: "ChatBabyTime | ", size: 18, color: mint, bold: true }), new TextRun({ text: "Play Store Readiness Report", size: 18, color: "999999" })]
        })] })
      },
      footers: {
        default: new Footer({ children: [new Paragraph({
          alignment: AlignmentType.CENTER,
          children: [new TextRun({ text: "Page ", size: 18, color: "999999" }), new TextRun({ children: [PageNumber.CURRENT], size: 18, color: "999999" })]
        })] })
      },
      children: [

        // ===== 1. EXECUTIVE SUMMARY =====
        heading("1. Executive Summary (총평)"),
        para("ChatBabyTime은 한국어 자연어/음성 입력이라는 차별화된 핵심 기능을 갖춘 육아 기록 앱입니다. 현재 MVP 단계로, UI/UX 완성도는 높으나 상용 출시를 위해서는 안정성, 데이터 영속성, 핵심 기능 보강이 필요합니다."),
        spacer(100),

        // Score cards
        new Table({
          width: { size: 9360, type: WidthType.DXA }, columnWidths: [2340, 2340, 2340, 2340],
          rows: [new TableRow({ children: [
            scoreCell("6.5", "Overall Score", navy),
            scoreCell("8", "UI/UX Design", darkMint),
            scoreCell("5", "Stability", accentRed),
            scoreCell("7", "Differentiation", accentBlue),
          ] })]
        }),
        spacer(200),

        infoBox("Core Verdict",
          "UI 디자인과 NLP 입력 방식은 경쟁력 있으나, 데이터 손실 버그, 미구현 기능, 에러 처리 부재로 인해 현재 상태로 출시 시 리뷰 평점 2.5~3.0 예상. Phase 1 개선 후 출시 시 4.0+ 달성 가능."
        ),
        spacer(200),

        // ===== 2. MARKET CONTEXT =====
        heading("2. Market Context (시장 분석)"),
        h2("2.1 글로벌 시장 규모"),
        para("육아 앱 시장은 2025년 USD 10.6억에서 2026년 USD 12.7억으로 성장 중이며, 2034년까지 연평균 20.37%의 성장률이 예상됩니다."),
        spacer(50),

        h2("2.2 주요 경쟁사 분석"),
        new Table({
          width: { size: 9360, type: WidthType.DXA }, columnWidths: [1800, 1000, 1200, 2560, 2800],
          rows: [
            new TableRow({ children: [
              headerCell("앱 이름", 1800), headerCell("평점", 1000), headerCell("다운로드", 1200),
              headerCell("핵심 강점", 2560), headerCell("수익 모델", 2800),
            ]}),
            new TableRow({ children: [
              cell("Huckleberry", 1800, { bold: true }),
              cell("4.8", 1000, { align: AlignmentType.CENTER }),
              cell("5M+", 1200, { align: AlignmentType.CENTER }),
              cell("AI 수면 예측 (SweetSpot)", 2560),
              cell("Freemium ($9.99/mo)", 2800),
            ]}),
            new TableRow({ children: [
              cell("Baby+", 1800, { bold: true, fill: lightGray }),
              cell("4.8", 1000, { align: AlignmentType.CENTER, fill: lightGray }),
              cell("12M+", 1200, { align: AlignmentType.CENTER, fill: lightGray }),
              cell("종합 트래킹 + 커뮤니티", 2560, { fill: lightGray }),
              cell("Freemium + Ads", 2800, { fill: lightGray }),
            ]}),
            new TableRow({ children: [
              cell("BabyTime", 1800, { bold: true }),
              cell("4.7", 1000, { align: AlignmentType.CENTER }),
              cell("10M+", 1200, { align: AlignmentType.CENTER }),
              cell("커스텀 차트, 아시아 25% 점유", 2560),
              cell("Freemium", 2800),
            ]}),
            new TableRow({ children: [
              cell("BabyLog", 1800, { bold: true, fill: lightGray }),
              cell("4.9", 1000, { align: AlignmentType.CENTER, fill: lightGray }),
              cell("1M+", 1200, { align: AlignmentType.CENTER, fill: lightGray }),
              cell("한 손 조작 최적화", 2560, { fill: lightGray }),
              cell("Freemium", 2800, { fill: lightGray }),
            ]}),
            new TableRow({ children: [
              cell("ChatBabyTime", 1800, { bold: true, color: mint }),
              cell("-", 1000, { align: AlignmentType.CENTER }),
              cell("신규", 1200, { align: AlignmentType.CENTER }),
              cell("한국어 NLP/음성 입력", 2560, { color: mint }),
              cell("미정", 2800),
            ]}),
          ]
        }),
        spacer(100),

        h2("2.3 한국 시장 기회"),
        para("현재 한국어에 특화된 전용 육아 기록 앱은 부재합니다. 글로벌 앱들이 한국어 번역을 지원하지만, 한국어 자연어 처리 입력은 제공하지 않습니다. 이것이 ChatBabyTime의 가장 큰 시장 기회입니다."),
        spacer(100),

        // ===== 3. SWOT ANALYSIS =====
        heading("3. SWOT Analysis"),
        new Table({
          width: { size: 9360, type: WidthType.DXA }, columnWidths: [4680, 4680],
          rows: [
            new TableRow({ children: [
              new TableCell({ borders, width: { size: 4680, type: WidthType.DXA },
                shading: { fill: "E8F8F5", type: ShadingType.CLEAR }, margins: { top: 120, bottom: 120, left: 160, right: 160 },
                children: [
                  new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "Strengths (강점)", bold: true, size: 24, color: accentGreen })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 60 }, children: [new TextRun({ text: "한국어 NLP/음성 입력 (유일한 차별점)", size: 20 })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 60 }, children: [new TextRun({ text: "세련된 다크 테마 UI (Midnight Nursery)", size: 20 })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 60 }, children: [new TextRun({ text: "대화형 기록 방식 (Chat UX)", size: 20 })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 60 }, children: [new TextRun({ text: "로컬 저장으로 개인정보 안전", size: 20 })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: "12개 카테고리 세분화 트래킹", size: 20 })] }),
                ]
              }),
              new TableCell({ borders, width: { size: 4680, type: WidthType.DXA },
                shading: { fill: "FDF2E9", type: ShadingType.CLEAR }, margins: { top: 120, bottom: 120, left: 160, right: 160 },
                children: [
                  new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "Weaknesses (약점)", bold: true, size: 24, color: accentOrange })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 60 }, children: [new TextRun({ text: "마일스톤/성장곡선 데이터 저장 안 됨", size: 20 })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 60 }, children: [new TextRun({ text: "에러 처리 전반적 부재", size: 20 })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 60 }, children: [new TextRun({ text: "다중 보호자 동기화 미지원", size: 20 })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 60 }, children: [new TextRun({ text: "데이터 백업/복원 기능 없음", size: 20 })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: "12개월 이후 콘텐츠 부재", size: 20 })] }),
                ]
              }),
            ]}),
            new TableRow({ children: [
              new TableCell({ borders, width: { size: 4680, type: WidthType.DXA },
                shading: { fill: "EBF5FB", type: ShadingType.CLEAR }, margins: { top: 120, bottom: 120, left: 160, right: 160 },
                children: [
                  new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "Opportunities (기회)", bold: true, size: 24, color: accentBlue })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 60 }, children: [new TextRun({ text: "한국 전용 육아 앱 시장 공백", size: 20 })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 60 }, children: [new TextRun({ text: "AI 기반 육아 가이드 프리미엄화", size: 20 })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 60 }, children: [new TextRun({ text: "소아과 리포트 내보내기 기능", size: 20 })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: "육아 커뮤니티/SNS 연동 가능성", size: 20 })] }),
                ]
              }),
              new TableCell({ borders, width: { size: 4680, type: WidthType.DXA },
                shading: { fill: "FDEDEC", type: ShadingType.CLEAR }, margins: { top: 120, bottom: 120, left: 160, right: 160 },
                children: [
                  new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "Threats (위협)", bold: true, size: 24, color: accentRed })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 60 }, children: [new TextRun({ text: "글로벌 앱의 한국어 지원 강화", size: 20 })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 60 }, children: [new TextRun({ text: "Huckleberry 등 AI 앱의 시장 장악", size: 20 })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, spacing: { after: 60 }, children: [new TextRun({ text: "낮은 초기 리뷰 시 검색 노출 하락", size: 20 })] }),
                  new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: "로컬 전용 저장의 데이터 손실 위험", size: 20 })] }),
                ]
              }),
            ]}),
          ]
        }),
        spacer(200),

        // ===== 4. DETAILED EVALUATION =====
        heading("4. Detailed Evaluation (세부 평가)"),

        h2("4.1 UI/UX 디자인 (8/10)"),
        para("Midnight Nursery 디자인 시스템은 야간 수유 시 눈의 피로를 줄이는 다크 네이비 배경에 민트 액센트를 적용하여 육아 앱으로서 매우 적절합니다. 글래스모피즘 네비게이션 바, 자연스러운 애니메이션, 채팅형 인터페이스 등 트렌디한 디자인을 채택하고 있습니다."),
        spacer(50),
        new Table({
          width: { size: 9360, type: WidthType.DXA }, columnWidths: [2500, 2500, 4360],
          rows: [
            new TableRow({ children: [headerCell("항목", 2500), headerCell("점수", 2500), headerCell("비고", 4360)] }),
            new TableRow({ children: [cell("시각 디자인", 2500), cell(ratingBar(9), 2500), cell("다크 테마 + 민트 조합 우수", 4360)] }),
            new TableRow({ children: [cell("정보 구조", 2500, { fill: lightGray }), cell(ratingBar(7), 2500, { fill: lightGray }), cell("4탭 구조 명확, 서브메뉴 접근성 양호", 4360, { fill: lightGray })] }),
            new TableRow({ children: [cell("입력 편의성", 2500), cell(ratingBar(9), 2500), cell("NLP + 음성 = 핵심 차별점", 4360)] }),
            new TableRow({ children: [cell("피드백/반응성", 2500, { fill: lightGray }), cell(ratingBar(6), 2500, { fill: lightGray }), cell("에러/성공 피드백 부족, 로딩 상태 없음", 4360, { fill: lightGray })] }),
            new TableRow({ children: [cell("접근성", 2500), cell(ratingBar(4), 2500), cell("시맨틱 라벨 없음, 고대비 모드 없음", 4360)] }),
          ]
        }),
        spacer(100),

        h2("4.2 기능 완성도 (6/10)"),
        new Table({
          width: { size: 9360, type: WidthType.DXA }, columnWidths: [2800, 1200, 1200, 4160],
          rows: [
            new TableRow({ children: [headerCell("기능", 2800), headerCell("상태", 1200), headerCell("중요도", 1200), headerCell("비고", 4160)] }),
            new TableRow({ children: [cell("수유/수면/기저귀 기록", 2800), cell("Complete", 1200, { color: accentGreen, align: AlignmentType.CENTER }), cell("Must", 1200, { align: AlignmentType.CENTER, color: accentRed }), cell("핵심 기능 동작 확인됨", 4160)] }),
            new TableRow({ children: [cell("NLP 자연어 입력", 2800, { fill: lightGray }), cell("Complete", 1200, { color: accentGreen, align: AlignmentType.CENTER, fill: lightGray }), cell("Must", 1200, { align: AlignmentType.CENTER, color: accentRed, fill: lightGray }), cell("키워드 기반, 주요 패턴 지원", 4160, { fill: lightGray })] }),
            new TableRow({ children: [cell("음성 입력", 2800), cell("Complete", 1200, { color: accentGreen, align: AlignmentType.CENTER }), cell("Must", 1200, { align: AlignmentType.CENTER, color: accentRed }), cell("STT 한국어 지원, 에러 처리 부족", 4160)] }),
            new TableRow({ children: [cell("패턴 분석", 2800, { fill: lightGray }), cell("Complete", 1200, { color: accentGreen, align: AlignmentType.CENTER, fill: lightGray }), cell("Nice", 1200, { align: AlignmentType.CENTER, color: accentBlue, fill: lightGray }), cell("일간/주간/간격 분석 제공", 4160, { fill: lightGray })] }),
            new TableRow({ children: [cell("통계/차트", 2800), cell("Complete", 1200, { color: accentGreen, align: AlignmentType.CENTER }), cell("Must", 1200, { align: AlignmentType.CENTER, color: accentRed }), cell("수유량/수면 차트, 기간 선택", 4160)] }),
            new TableRow({ children: [cell("성장 기록 (키/몸무게)", 2800, { fill: lightGray }), cell("Broken", 1200, { color: accentRed, align: AlignmentType.CENTER, fill: lightGray }), cell("Must", 1200, { align: AlignmentType.CENTER, color: accentRed, fill: lightGray }), cell("입력 후 저장 안 됨 (Critical Bug)", 4160, { fill: lightGray })] }),
            new TableRow({ children: [cell("발달 마일스톤", 2800), cell("Broken", 1200, { color: accentRed, align: AlignmentType.CENTER }), cell("Nice", 1200, { align: AlignmentType.CENTER, color: accentBlue }), cell("체크 상태 영속성 없음 (재시작 시 초기화)", 4160)] }),
            new TableRow({ children: [cell("다중 보호자 동기화", 2800, { fill: lightGray }), cell("Missing", 1200, { color: accentRed, align: AlignmentType.CENTER, fill: lightGray }), cell("Must", 1200, { align: AlignmentType.CENTER, color: accentRed, fill: lightGray }), cell("경쟁사 필수 기능, 미구현", 4160, { fill: lightGray })] }),
            new TableRow({ children: [cell("데이터 백업/복원", 2800), cell("Missing", 1200, { color: accentRed, align: AlignmentType.CENTER }), cell("Must", 1200, { align: AlignmentType.CENTER, color: accentRed }), cell("Hive 로컬 전용, 폰 교체 시 데이터 유실", 4160)] }),
            new TableRow({ children: [cell("알림/리마인더", 2800, { fill: lightGray }), cell("Missing", 1200, { color: accentRed, align: AlignmentType.CENTER, fill: lightGray }), cell("Must", 1200, { align: AlignmentType.CENTER, color: accentRed, fill: lightGray }), cell("수유/약 시간 알림 없음", 4160, { fill: lightGray })] }),
            new TableRow({ children: [cell("소아과 리포트 내보내기", 2800), cell("Missing", 1200, { color: accentRed, align: AlignmentType.CENTER }), cell("Nice", 1200, { align: AlignmentType.CENTER, color: accentBlue }), cell("PDF/이미지 내보내기 미구현", 4160)] }),
          ]
        }),
        spacer(100),

        h2("4.3 기술 안정성 (5/10)"),
        h3("Critical Bugs (출시 차단)"),
        richBullet("growth_curve_screen.dart: ", "성장 기록(키/몸무게) 입력 후 데이터가 저장되지 않고 사라짐. 핵심 기능의 데이터 손실."),
        richBullet("milestone_screen.dart: ", "발달 마일스톤 체크 상태가 메모리에만 저장되어 앱 재시작 시 전부 초기화."),
        richBullet("pattern_screen.dart: ", "기록이 1개일 때 interval 계산에서 0으로 나누기 크래시 가능."),
        richBullet("statistics_screen.dart: ", "빈 리스트에 reduce() 호출 시 런타임 에러 발생 가능."),
        richBullet("chat_screen.dart: ", "late 변수 초기화 순서 문제로 잠재적 크래시."),
        spacer(50),

        h3("Major Issues (출시 전 권장 수정)"),
        richBullet("에러 처리 전무: ", "record_service.dart의 모든 async 메서드에 try-catch 없음. DB 오류 시 앱 크래시."),
        richBullet("음성 인식 실패 무시: ", "speech_service.dart에서 에러 발생 시 debugPrint만 출력, 사용자에게 알림 없음."),
        richBullet("NLP 파서 엣지 케이스: ", "\"분유 120\" 입력 시 \"분\" 키워드가 시간 파싱을 트리거할 수 있음."),
        richBullet("메모리 누수: ", "smart_input_bar.dart의 무한 Future.delayed 루프, 애니메이션 컨트롤러 미해제 가능성."),
        richBullet("하드코딩 데이터: ", "profile_screen.dart에 \"은석 외 1명 관리 중\" 하드코딩됨."),
        spacer(100),

        h2("4.4 Play Store 준비도 (4/10)"),
        new Table({
          width: { size: 9360, type: WidthType.DXA }, columnWidths: [3500, 1300, 4560],
          rows: [
            new TableRow({ children: [headerCell("Play Store 요구사항", 3500), headerCell("상태", 1300), headerCell("상세", 4560)] }),
            new TableRow({ children: [cell("앱 아이콘", 3500), cell("Missing", 1300, { color: accentRed, align: AlignmentType.CENTER }), cell("기본 Flutter 아이콘 사용 중", 4560)] }),
            new TableRow({ children: [cell("스플래시 스크린", 3500, { fill: lightGray }), cell("Missing", 1300, { color: accentRed, align: AlignmentType.CENTER, fill: lightGray }), cell("브랜드 첫인상 부재", 4560, { fill: lightGray })] }),
            new TableRow({ children: [cell("온보딩 플로우", 3500), cell("Partial", 1300, { color: accentOrange, align: AlignmentType.CENTER }), cell("프로필 설정만 있음, 기능 가이드 없음", 4560)] }),
            new TableRow({ children: [cell("개인정보처리방침", 3500, { fill: lightGray }), cell("Missing", 1300, { color: accentRed, align: AlignmentType.CENTER, fill: lightGray }), cell("Play Store 필수 요구사항", 4560, { fill: lightGray })] }),
            new TableRow({ children: [cell("마이크 권한 설명", 3500), cell("Missing", 1300, { color: accentRed, align: AlignmentType.CENTER }), cell("권한 요청 사유 문구 필요", 4560)] }),
            new TableRow({ children: [cell("스크린샷 (최소 2장)", 3500, { fill: lightGray }), cell("Missing", 1300, { color: accentRed, align: AlignmentType.CENTER, fill: lightGray }), cell("Play Store 등록용 스크린샷 미준비", 4560, { fill: lightGray })] }),
            new TableRow({ children: [cell("다국어 지원", 3500), cell("Korean Only", 1300, { color: accentOrange, align: AlignmentType.CENTER }), cell("글로벌 확장 불가, 한국 시장 특화는 OK", 4560)] }),
            new TableRow({ children: [cell("앱 크래시율 기준 (<1.09%)", 3500, { fill: lightGray }), cell("Risk", 1300, { color: accentRed, align: AlignmentType.CENTER, fill: lightGray }), cell("에러 처리 부재로 크래시 위험 높음", 4560, { fill: lightGray })] }),
          ]
        }),
        spacer(200),

        // ===== 5. COMPETITIVE POSITIONING =====
        heading("5. Competitive Positioning (경쟁 포지셔닝)"),

        h2("5.1 ChatBabyTime의 고유 가치 제안"),
        infoBox("Unique Value Proposition",
          "\"말 한마디로 끝나는 육아 기록\" - 한국어 자연어 입력으로 버튼 탭 없이 3초 만에 육아 기록 완료. 야간 수유 중 한 손으로, 눈을 거의 감은 채로 음성만으로 기록 가능."
        ),
        spacer(100),

        para("이 포지셔닝은 다음 근거로 유효합니다."),
        richBullet("경쟁사 대비 입력 시간: ", "Huckleberry/BabyTime은 카테고리 선택 > 하위 항목 > 수량 입력 > 저장까지 평균 4~6탭 필요. ChatBabyTime은 \"분유 120ml\" 음성 한 마디로 완료."),
        richBullet("한국 시장 공백: ", "한국어 NLP를 탑재한 육아 앱이 현재 부재. 한국 출산율 저하로 소수의 아이에 집중 투자하는 부모 증가 추세."),
        richBullet("야간 사용 최적화: ", "다크 테마 + 음성 입력 = 새벽 수유 시 완벽한 조합. 경쟁사의 밝은 UI는 야간 사용에 불편."),
        spacer(200),

        // ===== 6. MONETIZATION STRATEGY =====
        heading("6. Monetization Strategy (수익화 전략)"),

        h2("6.1 추천 모델: Freemium + Subscription"),
        new Table({
          width: { size: 9360, type: WidthType.DXA }, columnWidths: [1600, 3880, 3880],
          rows: [
            new TableRow({ children: [headerCell("티어", 1600), headerCell("무료 (Free)", 3880), headerCell("프리미엄 (Pro)", 3880)] }),
            new TableRow({ children: [
              cell("가격", 1600, { bold: true }),
              cell("무료", 3880),
              cell("월 4,900원 / 연 39,000원", 3880, { color: mint }),
            ]}),
            new TableRow({ children: [
              cell("기록", 1600, { bold: true, fill: lightGray }),
              cell("텍스트/음성 기록, 12개 카테고리", 3880, { fill: lightGray }),
              cell("무제한 + 사진 첨부", 3880, { fill: lightGray }),
            ]}),
            new TableRow({ children: [
              cell("통계", 1600, { bold: true }),
              cell("7일 통계, 기본 차트", 3880),
              cell("무제한 기간, 고급 분석, AI 인사이트", 3880),
            ]}),
            new TableRow({ children: [
              cell("동기화", 1600, { bold: true, fill: lightGray }),
              cell("로컬 저장만", 3880, { fill: lightGray }),
              cell("클라우드 백업 + 다중 기기 동기화", 3880, { fill: lightGray }),
            ]}),
            new TableRow({ children: [
              cell("내보내기", 1600, { bold: true }),
              cell("없음", 3880),
              cell("소아과 리포트 PDF, CSV 내보내기", 3880),
            ]}),
            new TableRow({ children: [
              cell("알림", 1600, { bold: true, fill: lightGray }),
              cell("기본 수유 알림", 3880, { fill: lightGray }),
              cell("맞춤 알림 + AI 수면 예측", 3880, { fill: lightGray }),
            ]}),
          ]
        }),
        spacer(100),

        h2("6.2 수익 예측 (보수적 시나리오)"),
        para("한국 시장 집중, 월 다운로드 2,000건 기준으로 전환율 5% 적용 시 월 매출 약 490,000원 (연 5,880,000원). 인스타그램 육아 커뮤니티 마케팅과 소아과 제휴로 다운로드 확대 시 연 2,000만원 이상 가능합니다."),
        spacer(200),

        // ===== 7. IMPROVEMENT ROADMAP =====
        heading("7. Improvement Roadmap (개선 로드맵)"),

        h2("Phase 1: Launch Blocker Fix (2~3주) - 출시 필수"),
        infoBox("Goal", "크래시 제거, 데이터 무결성 확보, Play Store 등록 요건 충족", "FEF9E7"),
        spacer(50),

        new Paragraph({ numbering: { reference: "phase1", level: 0 }, spacing: { after: 60 }, children: [
          new TextRun({ text: "Critical Bug 수정: ", bold: true, size: 22 }),
          new TextRun({ text: "성장곡선 데이터 저장, 마일스톤 영속성, 0 나누기, 빈 리스트 처리", size: 22 }),
        ]}),
        new Paragraph({ numbering: { reference: "phase1", level: 0 }, spacing: { after: 60 }, children: [
          new TextRun({ text: "전역 에러 처리: ", bold: true, size: 22 }),
          new TextRun({ text: "RecordService, SpeechService에 try-catch 추가, 사용자 에러 피드백 UI", size: 22 }),
        ]}),
        new Paragraph({ numbering: { reference: "phase1", level: 0 }, spacing: { after: 60 }, children: [
          new TextRun({ text: "Play Store 요건: ", bold: true, size: 22 }),
          new TextRun({ text: "앱 아이콘, 스플래시, 개인정보처리방침, 권한 설명 문구", size: 22 }),
        ]}),
        new Paragraph({ numbering: { reference: "phase1", level: 0 }, spacing: { after: 60 }, children: [
          new TextRun({ text: "하드코딩 제거: ", bold: true, size: 22 }),
          new TextRun({ text: "프로필 데이터 동적 바인딩, 사용자 이름 하드코딩 제거", size: 22 }),
        ]}),
        new Paragraph({ numbering: { reference: "phase1", level: 0 }, spacing: { after: 60 }, children: [
          new TextRun({ text: "NLP 파서 안정화: ", bold: true, size: 22 }),
          new TextRun({ text: "\"분유\" 등 키워드 충돌 해결, confidence 점수 실제 계산", size: 22 }),
        ]}),
        spacer(100),

        h2("Phase 2: Competitive Parity (4~6주) - 리뷰 4.0+ 목표"),
        infoBox("Goal", "경쟁사 대비 기본 기능 격차 해소, 사용자 이탈 방지", "EBF5FB"),
        spacer(50),

        new Paragraph({ numbering: { reference: "phase2", level: 0 }, spacing: { after: 60 }, children: [
          new TextRun({ text: "Push 알림: ", bold: true, size: 22 }),
          new TextRun({ text: "수유 간격 알림, 약 복용 리마인더 (firebase_messaging 활용)", size: 22 }),
        ]}),
        new Paragraph({ numbering: { reference: "phase2", level: 0 }, spacing: { after: 60 }, children: [
          new TextRun({ text: "데이터 백업/복원: ", bold: true, size: 22 }),
          new TextRun({ text: "Google Drive 백업 또는 JSON export/import 기능", size: 22 }),
        ]}),
        new Paragraph({ numbering: { reference: "phase2", level: 0 }, spacing: { after: 60 }, children: [
          new TextRun({ text: "온보딩 튜토리얼: ", bold: true, size: 22 }),
          new TextRun({ text: "3~4장 슬라이드로 NLP 입력법과 음성 기록 사용법 안내", size: 22 }),
        ]}),
        new Paragraph({ numbering: { reference: "phase2", level: 0 }, spacing: { after: 60 }, children: [
          new TextRun({ text: "삭제 확인 다이얼로그: ", bold: true, size: 22 }),
          new TextRun({ text: "record_detail_screen 삭제 시 확인 팝업, 실행 취소(Undo) 지원", size: 22 }),
        ]}),
        new Paragraph({ numbering: { reference: "phase2", level: 0 }, spacing: { after: 60 }, children: [
          new TextRun({ text: "위젯 지원: ", bold: true, size: 22 }),
          new TextRun({ text: "홈 화면 위젯으로 마지막 수유 시간, 다음 수유 예정 표시", size: 22 }),
        ]}),
        spacer(100),

        h2("Phase 3: Premium Differentiation (2~3개월) - 수익화"),
        infoBox("Goal", "유료 전환 유도, AI 기반 프리미엄 기능으로 시장 차별화", "F5EEF8"),
        spacer(50),

        new Paragraph({ numbering: { reference: "phase3", level: 0 }, spacing: { after: 60 }, children: [
          new TextRun({ text: "다중 보호자 동기화: ", bold: true, size: 22 }),
          new TextRun({ text: "Firebase 기반 실시간 동기화, 가족 초대 시스템", size: 22 }),
        ]}),
        new Paragraph({ numbering: { reference: "phase3", level: 0 }, spacing: { after: 60 }, children: [
          new TextRun({ text: "AI 수면 예측: ", bold: true, size: 22 }),
          new TextRun({ text: "수면 패턴 학습 후 최적 낮잠 시간 추천 (Huckleberry SweetSpot 대항)", size: 22 }),
        ]}),
        new Paragraph({ numbering: { reference: "phase3", level: 0 }, spacing: { after: 60 }, children: [
          new TextRun({ text: "소아과 리포트: ", bold: true, size: 22 }),
          new TextRun({ text: "성장곡선 + 수유/수면 패턴 PDF 내보내기 (소아과 방문 시 활용)", size: 22 }),
        ]}),
        new Paragraph({ numbering: { reference: "phase3", level: 0 }, spacing: { after: 60 }, children: [
          new TextRun({ text: "사진 일기: ", bold: true, size: 22 }),
          new TextRun({ text: "기록에 사진 첨부, 월별 포토 타임라인 생성", size: 22 }),
        ]}),
        new Paragraph({ numbering: { reference: "phase3", level: 0 }, spacing: { after: 60 }, children: [
          new TextRun({ text: "12개월+ 콘텐츠 확장: ", bold: true, size: 22 }),
          new TextRun({ text: "유아식, 배변훈련, 언어발달 등 36개월까지 마일스톤/팁 확장", size: 22 }),
        ]}),
        spacer(200),

        // ===== 8. PRIORITY MATRIX =====
        heading("8. Priority Matrix (우선순위 매트릭스)"),
        para("Impact(영향력) vs Effort(투입 공수) 기준으로 개선 항목을 분류합니다."),
        spacer(50),

        new Table({
          width: { size: 9360, type: WidthType.DXA }, columnWidths: [1560, 1560, 1560, 1560, 1560, 1560],
          rows: [
            new TableRow({ children: [
              new TableCell({ borders: noBorders, width: { size: 1560, type: WidthType.DXA }, children: [new Paragraph("")] }),
              new TableCell({ borders: noBorders, width: { size: 1560, type: WidthType.DXA }, children: [new Paragraph("")] }),
              new TableCell({ borders: { bottom: { style: BorderStyle.SINGLE, size: 2, color: navy }, top: noBorder, left: noBorder, right: noBorder },
                width: { size: 1560, type: WidthType.DXA }, children: [new Paragraph("")] }),
              new TableCell({ borders: { bottom: { style: BorderStyle.SINGLE, size: 2, color: navy }, top: noBorder, left: noBorder, right: noBorder },
                width: { size: 1560, type: WidthType.DXA }, children: [
                  new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "Low Effort", size: 18, bold: true, color: navy })] })
                ] }),
              new TableCell({ borders: { bottom: { style: BorderStyle.SINGLE, size: 2, color: navy }, top: noBorder, left: noBorder, right: noBorder },
                width: { size: 1560, type: WidthType.DXA }, children: [new Paragraph("")] }),
              new TableCell({ borders: { bottom: { style: BorderStyle.SINGLE, size: 2, color: navy }, top: noBorder, left: noBorder, right: noBorder },
                width: { size: 1560, type: WidthType.DXA }, children: [
                  new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "High Effort", size: 18, bold: true, color: navy })] })
                ] }),
            ] }),
            new TableRow({ children: [
              new TableCell({ borders: noBorders, width: { size: 1560, type: WidthType.DXA }, children: [
                new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "High", size: 18, bold: true, color: navy })] })
              ] }),
              new TableCell({ borders: noBorders, width: { size: 1560, type: WidthType.DXA }, children: [
                new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "Impact", size: 18, bold: true, color: navy })] })
              ] }),
              new TableCell({ borders, width: { size: 1560, type: WidthType.DXA },
                shading: { fill: "E8F8F5", type: ShadingType.CLEAR }, margins: cellMargins,
                children: [
                  new Paragraph({ spacing: { after: 40 }, children: [new TextRun({ text: "DO FIRST", size: 16, bold: true, color: accentGreen })] }),
                  new Paragraph({ spacing: { after: 30 }, children: [new TextRun({ text: "Bug fixes", size: 16 })] }),
                  new Paragraph({ spacing: { after: 30 }, children: [new TextRun({ text: "Error handling", size: 16 })] }),
                  new Paragraph({ children: [new TextRun({ text: "Hardcode removal", size: 16 })] }),
                ]
              }),
              new TableCell({ borders, width: { size: 1560, type: WidthType.DXA },
                shading: { fill: "E8F8F5", type: ShadingType.CLEAR }, margins: cellMargins,
                children: [
                  new Paragraph({ spacing: { after: 40 }, children: [new TextRun({ text: "DO FIRST", size: 16, bold: true, color: accentGreen })] }),
                  new Paragraph({ spacing: { after: 30 }, children: [new TextRun({ text: "Push Notifications", size: 16 })] }),
                  new Paragraph({ children: [new TextRun({ text: "Data backup", size: 16 })] }),
                ]
              }),
              new TableCell({ borders, width: { size: 1560, type: WidthType.DXA },
                shading: { fill: "FEF9E7", type: ShadingType.CLEAR }, margins: cellMargins,
                children: [
                  new Paragraph({ spacing: { after: 40 }, children: [new TextRun({ text: "PLAN", size: 16, bold: true, color: accentOrange })] }),
                  new Paragraph({ spacing: { after: 30 }, children: [new TextRun({ text: "Multi-caregiver sync", size: 16 })] }),
                  new Paragraph({ children: [new TextRun({ text: "AI sleep prediction", size: 16 })] }),
                ]
              }),
              new TableCell({ borders, width: { size: 1560, type: WidthType.DXA },
                shading: { fill: "FEF9E7", type: ShadingType.CLEAR }, margins: cellMargins,
                children: [
                  new Paragraph({ spacing: { after: 40 }, children: [new TextRun({ text: "PLAN", size: 16, bold: true, color: accentOrange })] }),
                  new Paragraph({ spacing: { after: 30 }, children: [new TextRun({ text: "Photo diary", size: 16 })] }),
                  new Paragraph({ children: [new TextRun({ text: "Doctor reports", size: 16 })] }),
                ]
              }),
            ] }),
            new TableRow({ children: [
              new TableCell({ borders: noBorders, width: { size: 1560, type: WidthType.DXA }, children: [
                new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "Low", size: 18, bold: true, color: navy })] })
              ] }),
              new TableCell({ borders: noBorders, width: { size: 1560, type: WidthType.DXA }, children: [
                new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "Impact", size: 18, bold: true, color: navy })] })
              ] }),
              new TableCell({ borders, width: { size: 1560, type: WidthType.DXA },
                shading: { fill: "E8F8F5", type: ShadingType.CLEAR }, margins: cellMargins,
                children: [
                  new Paragraph({ spacing: { after: 40 }, children: [new TextRun({ text: "QUICK WIN", size: 16, bold: true, color: accentGreen })] }),
                  new Paragraph({ spacing: { after: 30 }, children: [new TextRun({ text: "App icon", size: 16 })] }),
                  new Paragraph({ spacing: { after: 30 }, children: [new TextRun({ text: "Splash screen", size: 16 })] }),
                  new Paragraph({ children: [new TextRun({ text: "Delete confirmation", size: 16 })] }),
                ]
              }),
              new TableCell({ borders, width: { size: 1560, type: WidthType.DXA },
                shading: { fill: "E8F8F5", type: ShadingType.CLEAR }, margins: cellMargins,
                children: [
                  new Paragraph({ spacing: { after: 40 }, children: [new TextRun({ text: "QUICK WIN", size: 16, bold: true, color: accentGreen })] }),
                  new Paragraph({ spacing: { after: 30 }, children: [new TextRun({ text: "Onboarding", size: 16 })] }),
                  new Paragraph({ children: [new TextRun({ text: "Privacy policy", size: 16 })] }),
                ]
              }),
              new TableCell({ borders, width: { size: 1560, type: WidthType.DXA },
                shading: { fill: "FDEDEC", type: ShadingType.CLEAR }, margins: cellMargins,
                children: [
                  new Paragraph({ spacing: { after: 40 }, children: [new TextRun({ text: "DEFER", size: 16, bold: true, color: accentRed })] }),
                  new Paragraph({ spacing: { after: 30 }, children: [new TextRun({ text: "Light mode", size: 16 })] }),
                  new Paragraph({ children: [new TextRun({ text: "i18n (multi-language)", size: 16 })] }),
                ]
              }),
              new TableCell({ borders, width: { size: 1560, type: WidthType.DXA },
                shading: { fill: "FDEDEC", type: ShadingType.CLEAR }, margins: cellMargins,
                children: [
                  new Paragraph({ spacing: { after: 40 }, children: [new TextRun({ text: "DEFER", size: 16, bold: true, color: accentRed })] }),
                  new Paragraph({ spacing: { after: 30 }, children: [new TextRun({ text: "Apple Watch", size: 16 })] }),
                  new Paragraph({ children: [new TextRun({ text: "Community features", size: 16 })] }),
                ]
              }),
            ] }),
          ]
        }),
        spacer(200),

        // ===== 9. FINAL RECOMMENDATION =====
        heading("9. Final Recommendation (최종 권고)"),

        new Table({
          width: { size: 9360, type: WidthType.DXA }, columnWidths: [9360],
          rows: [new TableRow({ children: [new TableCell({
            borders: { top: { style: BorderStyle.SINGLE, size: 8, color: mint }, bottom: { style: BorderStyle.SINGLE, size: 8, color: mint }, left: noBorder, right: noBorder },
            width: { size: 9360, type: WidthType.DXA },
            shading: { fill: "0D1B2A", type: ShadingType.CLEAR },
            margins: { top: 200, bottom: 200, left: 300, right: 300 },
            children: [
              new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 120 }, children: [
                new TextRun({ text: "Recommendation: Conditional GO", size: 32, bold: true, color: mint }),
              ]}),
              new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 120 }, children: [
                new TextRun({ text: "Phase 1 완료 후 출시 권고 (예상 소요: 2~3주)", size: 24, color: white }),
              ]}),
              new Paragraph({ alignment: AlignmentType.CENTER, children: [
                new TextRun({ text: "현재 상태 예상 평점: 2.5~3.0", size: 22, color: accentRed }),
                new TextRun({ text: "  |  ", size: 22, color: "666666" }),
                new TextRun({ text: "Phase 1 후 예상 평점: 4.0~4.3", size: 22, color: accentGreen }),
                new TextRun({ text: "  |  ", size: 22, color: "666666" }),
                new TextRun({ text: "Phase 2+3 후: 4.5+", size: 22, color: mint }),
              ]}),
            ]
          })] })]
        }),
        spacer(200),

        para("ChatBabyTime은 \"한국어 자연어 입력\"이라는 명확한 차별점과 우수한 UI를 갖추고 있어 상용화 가능성이 충분합니다. 다만, 현재 상태에서 바로 출시하면 데이터 손실 버그와 크래시로 인해 초기 리뷰가 치명적으로 나빠질 수 있습니다. Phase 1의 버그 수정과 안정화를 먼저 완료하고, 한국 육아 커뮤니티(맘카페, 인스타그램)를 타겟으로 소프트 런칭하는 것을 권고합니다."),
        spacer(100),
        para("핵심은 속도입니다. 한국 시장에 NLP 기반 육아 앱이 없는 지금이 기회의 창이며, Phase 1만 완료하면 충분히 경쟁력 있는 제품으로 시장에 진입할 수 있습니다."),
      ]
    }
  ]
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("/sessions/elegant-eager-pasteur/mnt/ChatBabyTime/ChatBabyTime_상품성평가보고서.docx", buffer);
  console.log("Report generated: " + buffer.length + " bytes");
});

# Google Stitch Prompt — ChatBabyTime

## App Overview

Design a complete mobile app called **"ChatBabyTime"** — an AI-powered **chat-based baby care tracker**. The core idea: parents simply **type or speak naturally** — like talking to ChatGPT — and the AI automatically parses the input, extracts structured data, and creates baby care records. No buttons to tap, no forms to fill. Just talk.

**The core experience:** A chat interface where the parent says "분유 120ml 먹었어" and the AI instantly responds "🍼 분유 120ml 기록했어요! 오늘 총 수유량 360ml이에요." The chat doubles as a living timeline — every record is a conversation. Parents can also ask questions like "오늘 수유 몇 번 했지?" and get instant answers from their own data.

**What makes it different from 베이비타임:** BabyTime requires tapping icons → filling forms → saving. ChatBabyTime requires **one sentence**. The AI handles all the parsing, categorization, and structured data extraction behind the scenes.

**Tagline:** "말 한마디로 끝나는 육아 기록"
**Target platform:** Flutter (iOS & Android)
**Primary language:** Korean (all UI text in Korean)
**Design system:** Dark theme (Midnight Nursery) — optimized for nighttime use

---

## Brand & Color Palette (Midnight Nursery Dark Theme)

- **Background:** `#111125` (Deep Navy) — main app background
- **Surface Container:** `#1E1E32` — cards, chat bubbles (AI side)
- **Surface High:** `#28283D` — elevated surfaces
- **Surface Bright:** `#37374D` — category icon backgrounds
- **Primary (Accent):** `#46F1C5` (Mint/Teal Glow) — AI highlights, confirmed records, active states
- **Secondary:** `#C5C4E2` (Lavender) — sleep-related, secondary text
- **Tertiary:** `#FFD268` (Warm Gold) — dates, warnings, diaper/health category
- **On Surface:** `#E2E0FC` (Soft White-Lavender) — primary text
- **On Surface Variant:** `#BAC AC2` — secondary text, timestamps
- **Outline Variant:** `#3B4A44` — borders, dividers
- **Category Colors:**
  - 수유 (Feeding): `#46F1C5` (Mint)
  - 수면 (Sleep): `#C5C4E2` (Lavender)
  - 기저귀 (Diaper): `#FFD268` (Gold)
  - 건강 (Health): `#98D8C8` (Soft Mint)
  - 성장 (Milestone): `#FFDF9B` (Light Gold)
- **User Chat Bubble:** `#46F1C5` with `#00382B` text (mint bubble, dark text)
- **AI Chat Bubble:** `#1E1E32` with `#E2E0FC` text (dark bubble, light text)
- **Error:** `#FFB4AB`
- **Font:** Noto Sans KR (Google Fonts)
- **Border radius:** 16px for cards/bubbles, 24px for buttons/chips, 28px for FAB
- **Overall mood:** Dark, cozy, glowing — like a warm nightlight in a nursery

---

## Navigation Structure

### Bottom Navigation Bar (5 tabs)

1. **채팅** (Chat) — Main AI chat screen for recording ← DEFAULT TAB, PRIMARY INTERACTION
2. **패턴** (Pattern) — Activity pattern analysis (daily schedule, weekly pattern, interval pattern)
3. **통계** (Statistics) — Charts and graphs for weekly/monthly data
4. **공개일기** (Public Diary) — Community growth diary feed
5. **프로필** (Profile) — Baby info, milestones, growth curve

- Frosted glass effect navbar with blur backdrop
- Selected tab: Primary mint color with bold label
- Unselected: `onSurfaceVariant` muted color
- Rounded top corners (24px radius)

---

## Screen 1: 채팅 (Chat) — Main AI Chat Screen ★ PRIMARY SCREEN

**Route:** `/chat` — This is the HOME screen and the heart of the app.

### Concept
The chat screen works like a messaging app. The parent is one side, the AI assistant "베비" is the other side. Every message from the parent is analyzed by a **Korean NLP parser** that extracts: category (수유/수면/기저귀/건강/etc.), sub-type, amount, duration, time, and any memo. The AI responds with a structured confirmation card and a friendly message.

### Top Header Bar
- Left: AI avatar (small circle) + **"베비"** name label
- Center: Baby age display — **"13개월 18일 (D+411)"** in primary color
- Right: **⋯** menu button → settings, search records, usage tips

### Chat Area (Scrollable Message List)
The main body is a **reverse-chronological chat feed**, newest messages at the bottom:

#### User Message Bubble (Right-aligned, Mint)
```
┌─────────────────────────┐
│ 이유식 160ml 먹었어       │
│ 소고기랑 명란계란말이      │
└─────────────────────────┘
                    오후 12:00
```
- Background: Primary mint (`#46F1C5`)
- Text: Dark (`#00382B`)
- Rounded corners (top-left, top-right, bottom-left rounded; bottom-right sharp)
- Timestamp below

#### AI Response — Record Confirmation Card (Left-aligned, Dark)
When the AI successfully parses a record, it responds with:
```
┌─ 🍼 ────────────────────────┐
│  ✅ 이유식 기록 완료!          │
│                              │
│  🕐 오후 12:00               │
│  📏 160ml                    │
│  🏷️ 소고기, 명란계란말이       │
│                              │
│  ┌──────┐  ┌──────┐         │
│  │ ✏️ 수정 │  │ ❌ 취소 │         │
│  └──────┘  └──────┘         │
└──────────────────────────────┘

오늘 총 이유식 320ml이에요!
오전보다 잘 먹었네요 😊
```
- **Category emoji + label** at top with colored accent line
- **Structured data fields** clearly laid out (time, amount, tags, memo)
- **Action buttons:** "수정" (edit) and "취소" (cancel/delete)
- **Friendly follow-up message** with today's summary context
- Background: Surface container (`#1E1E32`)
- Text: On surface (`#E2E0FC`)

#### AI Response — Ambiguous Input
When the AI is not confident about the parsing:
```
┌──────────────────────────────┐
│  🤔 이렇게 기록할까요?         │
│                              │
│  카테고리: 수유 (분유)         │
│  양: 120ml                   │
│  시간: 지금                   │
│                              │
│  정확도: 75%                  │
│                              │
│  ┌──────┐  ┌──────┐         │
│  │ ✅ 맞아요│  │ ✏️ 수정 │         │
│  └──────┘  └──────┘         │
└──────────────────────────────┘
```
- Yellow/gold accent border to indicate uncertainty
- Shows parsing confidence percentage
- User confirms or edits before saving

#### AI Response — Data Query Answer
When the parent asks a question about records:
```
User: "오늘 수유 몇 번 했지?"

AI: 📊 오늘의 수유 기록이에요!

    총 3회 | 총 480ml

    🍼 오전 08:00 — 분유 160ml
    🍼 오후 12:00 — 이유식 160ml
    🍼 오후 05:30 — 이유식 160ml

    어제(480ml) 대비 동일해요!
```

#### AI Daily Greeting (Auto-generated)
At the top of each new day, the AI sends a greeting:
```
🌅 좋은 아침이에요!
오복이 D+411일째 — 13개월 18일

어제 요약:
🍼 수유 3회 (480ml) | 😴 수면 10시간 32분 | 🧷 기저귀 5회

오늘도 화이팅! 💪
```

### Quick Action Chips (Above Input Bar)
Horizontally scrollable shortcut chips for common records:
- 🍼 **분유** → auto-fills "분유 먹었어"
- 🤱 **모유** → auto-fills "모유 수유했어"
- 😴 **잠듦** → auto-fills "아기 잠들었어"
- 👀 **깸** → auto-fills "아기 깼어"
- 🧷 **기저귀** → auto-fills "기저귀 갈았어"
- 💩 **응가** → auto-fills "기저귀 갈았어 응가"

Tapping a chip fills the input bar with the preset text, which the user can modify or send directly.

### Smart Input Bar (Bottom, Always Visible)
- **Text input field** with rotating placeholder hints:
  - "베비에게 말해보세요..."
  - "분유 120ml 먹었어"
  - "아기 방금 잠들었어"
  - "기저귀 갈았어 응가"
  - "오늘 수유 몇 번 했지?"
- **Send button** (arrow icon) — appears when text is entered, primary color
- **Microphone FAB** (right side) — tap to start voice input
  - While listening: pulsing glow animation around mic, red color
  - Shows real-time speech-to-text transcription above input bar
  - Auto-submits when speech ends
- **Safe area padding** at bottom for iOS home indicator

### Today Summary Card (Collapsible, above chat)
Small card at the very top of chat that shows today's quick stats:
- 🍼 수유 3회 (480ml) | 😴 수면 2회 | 🧷 기저귀 4회
- Tap to expand → shows last record timers:
  - 마지막 수유: 2시간 30분 전
  - 마지막 수면: 4시간 15분 전
  - 마지막 기저귀: 1시간 10분 전

---

## NLP Parser — The Brain of the App

### How It Works
The NLP parser is a **local, offline Korean natural language processor** (no API calls needed). It runs entirely on-device for instant responses.

### Input Examples & Expected Parsing

| User Input | Category | Sub-type | Amount | Time | Memo |
|---|---|---|---|---|---|
| "분유 120ml 먹었어" | 수유 | 분유 | 120ml | now | — |
| "오후 2시에 이유식 160ml 소고기" | 수유 | 이유식 | 160ml | 14:00 | 소고기 |
| "모유 수유 15분" | 수유 | 모유 | — | now | 15분 |
| "아기 잠들었어" | 수면 | — | — | now | 잠듦 |
| "방금 깼어" | 수면 | — | — | now | 깨어남 |
| "기저귀 갈았어 응가" | 기저귀 | 대변 | — | now | — |
| "30분 전에 기저귀 갈았어" | 기저귀 | 소변 | — | -30min | — |
| "체온 37.5도" | 건강 | 체온 | 37.5°C | now | — |
| "오늘 수유 몇 번?" | 질문 | — | — | — | — |

### Time Expression Parsing
- "방금", "지금", "막" → current time
- "N분 전" → now - N minutes
- "N시간 전" → now - N hours
- "오전/오후 N시 M분" → absolute time
- "N시 M분" → absolute time (infers AM/PM)
- "HH:MM" format → absolute time

### Category Detection Keywords
- **수유:** 수유, 분유, 모유, 우유, 젖, 먹, 밥, 이유식, ml, 밀리, 간식, 물, 주스, 죽, cc
- **수면:** 잠, 자, 수면, 깨, 일어나, 낮잠, 취침, 기상, 잤, 깸, 눈떠, 재우
- **기저귀:** 기저귀, 응가, 똥, 소변, 대변, 갈았, 싸, 오줌, 변, 배변
- **건강:** 체온, 열, 온도, 약, 병원, 예방접종, 감기, 기침, 콧물
- **질문:** 몇 번, 몇 회, 얼마나, 언제, 알려줘, 보여줘

### Confidence Scoring
- 0.9+ → Auto-save with confirmation card
- 0.7–0.89 → Show "이렇게 기록할까요?" confirmation dialog
- 0.3–0.69 → Show parsed result with edit option, yellow warning
- Below 0.3 → Save as "기타" category with original text as memo

---

## Screen 2: 패턴 (Pattern) — Activity Pattern Analysis

**Route:** `/pattern`

### Top Tab Bar (3 sub-tabs)
1. **일과표** (Daily Schedule) — Visual daily timeline
2. **주간 패턴** (Weekly Pattern) — Weekly activity heatmap/pattern
3. **간격 패턴** (Interval Pattern) — Time intervals between same-type records

### Category Filter Bar
- Circular category icons (smaller, horizontally scrollable)
- Single-select mode for interval pattern, multi-select for others
- Label: "19개 중 1개 선택됨" (1 of 19 selected)

### Interval Pattern View (간격 패턴)
Vertical timeline showing records of the selected category with **time intervals** between them:

**Each entry:**
- Left side: **Interval badge** — "10시간 51분", "1일 17시간", "23시간 11분"
  - Shows time elapsed since previous record of same type
- Center: Vertical timeline line with colored dot
- Right side: Time + Record details
  - "12:00 PM" + "이유식 소고기, 비타민d" + "160 ml" + memo
- **Date separators:** "오늘", "3월 19일 (목)", "3월 18일 (수)"

### Daily Schedule View (일과표)
- Horizontal bar chart showing activity blocks across 24 hours
- Color-coded by category (mint=feeding, lavender=sleep, gold=diaper)
- Shows sleep blocks, feeding times, diaper changes visually

### Weekly Pattern View (주간 패턴)
- 7-day grid showing activity patterns
- Helps identify routine formation

---

## Screen 3: 통계 (Statistics) — Charts & Graphs

**Route:** `/statistics`

### Top Controls
- **Period toggle:** 일 (Day) / 주 (Week) / 월 (Month)
- **Settings gear icon** — configure which stats to show
- **Date range display:** "📅 3월 15일 - 21일" with left/right arrows

### Graph Section
- Title: "📈 그래프" with header bar (gold background)
- **"＋ 그래프 추가하기"** button — add custom graphs
- Available graph types:
  - 수유량 추이 (Feeding amount trend) — line chart
  - 수면 시간 (Sleep duration) — bar chart
  - 기저귀 횟수 (Diaper frequency) — bar chart
  - 체중/키 성장 (Weight/height growth) — line chart
- Charts rendered with fl_chart

### Summary Statistics
- Total counts and averages for the selected period
- Comparison with previous period (▲▼ indicators)

---

## Screen 4: 공개일기 (Public Diary) — Community Growth Diary

**Route:** `/diary`

### Top Toggle
- **출생일별 성장일기** (by birth date) — babies at same D+ day
- **전체 성장일기** (all) — all entries

### Date Navigation
- Center: **"D+411"** with left/right arrows

### Diary Feed
Each entry card:
- **Baby nickname** (e.g., "시유") + cute avatar icon
- **⋯** menu button
- **Diary text** — free-form growth update
- **Growth data** (optional): 체중 10.8 kg, 키 - cm
- **Engagement:** likes, comments

---

## Screen 5: 프로필 (Profile) — Baby Info & Growth

**Route:** `/profile`

### Baby Info Card
- Baby avatar (customizable cute illustrations)
- Name with dropdown (switch between babies)
- Age: "D+411, 58주 5일"
- Caregivers: "은석 외 1명"

### Feature Buttons (2x2 grid)
1. **성장 분석 보고서** — AI growth report
2. **마일스톤 (발달 체크)** — milestone tracker
3. **성장곡선** — WHO growth curve chart
4. **육아 및 발달 정보** — age-appropriate tips

### Growth Diary Section
- Diary entry thumbnails carousel
- CTA to write first diary with weight, height, photos
- Gold pencil FAB for new entry

---

## Onboarding Flow

### Step 1 — Welcome
- App logo + cute AI bear character "베비"
- "말 한마디로 끝나는 육아 기록"
- Sub-text: "ChatGPT처럼 말하면 자동으로 기록돼요"

### Step 2 — Demo Conversation
- Animated demo showing:
  - User types "분유 120ml 먹었어"
  - AI responds with record confirmation card
  - Shows how easy it is

### Step 3 — Baby Profile Setup
- Baby name, nickname, birth date, gender
- Birth weight/height (optional)
- Profile avatar selection

### Step 4 — Caregiver Setup
- Primary caregiver name
- Invite link for shared parenting

**Bottom CTA:** "시작하기" (Get Started)

---

## Data Model

### BabyProfile
- id, name, nickname, birthDate, gender
- birthWeight, birthHeight
- avatarType, caregivers[]

### BabyRecord
- id, babyId, category, subType
- dateTime, duration (for sleep)
- amount, unit (for feeding — ml)
- tags[] (ingredients for baby food)
- memo, stoolColor (for diaper)
- temperature (for health)
- **rawInput** — original user chat text that created this record
- **confidence** — NLP parsing confidence (0.0–1.0)

### ChatMessage
- id, babyId, timestamp
- sender: user | ai
- text: display text
- **linkedRecordId** — if this message created/modified a record
- messageType: record_confirm | record_question | query_answer | greeting | general

### GrowthEntry (Diary)
- id, babyId, date
- weight, height, headCircumference
- photos[], diaryText
- isPublic (for 공개일기)

### Categories & SubTypes
```
모유 (Breast milk): 왼쪽/오른쪽/양쪽, duration(min)
분유 (Formula): amount(ml)
이유식 (Baby food): amount(ml), ingredients[], memo
간식 (Snack): memo
물/음료 (Water/Drink): amount(ml)
기저귀 (Diaper): 소변/대변/혼합, stoolColor
수면 (Sleep): 낮잠/밤잠, start/end
유축 수유 (Pumped milk): amount(ml)
체온 (Temperature): value(°C)
약 (Medicine): name, dosage
키/몸무게 (Height/Weight): height(cm), weight(kg)
병원 (Hospital): memo
목욕 (Bath): duration
외출 (Outing): memo
```

---

## Key Features Summary

### 🌟 Core (Chat-based Recording)
1. **AI 채팅 기록** — Type or speak naturally, AI auto-parses and creates structured records
2. **음성 입력** — Tap mic, speak, auto-transcribe and submit (speech-to-text)
3. **NLP 한국어 파서** — On-device Korean natural language parser (no API, offline-capable)
4. **파싱 확인** — AI shows parsed result with confidence %, user confirms or edits
5. **빠른 액션 칩** — Quick-tap chips ("분유", "잠듦", "응가") for one-tap common records
6. **데이터 질의** — Ask questions about records ("오늘 수유 몇 번?") and get instant answers
7. **일일 인사/요약** — AI greets each morning with yesterday's summary

### 📊 Analysis (BabyTime-inspired features)
8. **패턴 분석** — Daily schedule, weekly pattern, interval pattern views
9. **통계 그래프** — Customizable charts (daily/weekly/monthly trends)
10. **마지막 기록 타이머** — Real-time elapsed timers since last feed/sleep/diaper
11. **일별 요약** — Daily summary with total feeding, sleep hours, diaper count

### 👶 Growth & Community
12. **성장 기록** — Weight, height, head circumference with growth curves
13. **마일스톤 체크** — Developmental milestone tracker
14. **성장 분석 보고서** — AI-generated growth report
15. **공개일기** — Community diary feed filtered by baby's birth date (D+ day)

### ⚙️ Utility
16. **다중 아기 지원** — Switch between multiple baby profiles
17. **공동 육아** — Invite caregivers to share records
18. **기록 검색** — Search past records by keyword
19. **스톱워치** — Built-in timer for feeding/sleep duration

---

## Technical Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.x |
| State Management | Provider |
| Local DB | Hive |
| NLP Parser | Custom Dart (on-device, no API) |
| Speech-to-Text | speech_to_text package |
| Charts | fl_chart |
| Date/Time | intl package |
| UUID | uuid package |

---

## Design Principles

1. **Chat-first:** The primary interaction is conversational. No forms, no multi-step wizards. Just type or speak.
2. **Dark theme for night use:** Deep navy background with glowing mint accents — comfortable for 3am feedings.
3. **AI that feels human:** 베비 responds with emoji, encouragement, and context-aware summaries. Not robotic.
4. **Zero learning curve:** If you can text a friend, you can use this app. The NLP handles the rest.
5. **Data power behind simplicity:** Chat looks simple, but the structured data behind it powers rich pattern analysis, statistics, and growth tracking.
6. **Korean-native:** All NLP parsing, date formats ("3월 21일 (토)"), age formats ("13개월 18일"), and cultural context are authentically Korean.
7. **Offline-first:** NLP parsing and all data storage work without internet. The app works in airplane mode.

---

## Sample Chat Conversation

```
─────────── 3월 21일 (토) ───────────

🤖 베비:
🌅 좋은 아침이에요, 은석님!
오복이 D+411일째 — 13개월 18일

어제 요약:
🍼 수유 2회 (320ml) | 😴 수면 9시간 48분 | 🧷 기저귀 4회

오늘도 화이팅! 💪

─────────────────────────────────────

                    ┌──────────────────┐
                    │ 이유식 160ml 먹었어  │
                    │ 소고기 명란계란말이   │
                    └──────────────────┘
                              오후 12:00

🤖 베비:
┌─ 🥣 ─────────────────────────┐
│  ✅ 이유식 기록 완료!           │
│  🕐 오후 12:00                │
│  📏 160ml                     │
│  🏷️ 소고기, 명란계란말이        │
│  [✏️ 수정]  [❌ 취소]           │
└───────────────────────────────┘

소고기 잘 먹었네요! 오늘 첫 이유식이에요 🎉

─────────────────────────────────────

                    ┌──────────────────┐
                    │ 기저귀 갈았어 응가   │
                    └──────────────────┘
                              오후 12:26

🤖 베비:
┌─ 💩 ─────────────────────────┐
│  ✅ 기저귀 (대변) 기록 완료!     │
│  🕐 오후 12:26                │
│  [✏️ 수정]  [❌ 취소]           │
└───────────────────────────────┘

오늘 기저귀 2번째예요.

─────────────────────────────────────

                    ┌──────────────────┐
                    │ 오늘 뭐 먹었지?     │
                    └──────────────────┘
                              오후 1:30

🤖 베비:
📊 오늘의 수유 기록이에요!

총 1회 | 총 160ml

🥣 오후 12:00 — 이유식 160ml (소고기, 명란계란말이)

아직 하루가 남았어요! 😊
```

---

## Sample Interval Pattern (이유식)

```
                        오늘
 ┌──────────┐
 │10시간 51분│  12:00 PM ●── 이유식 소고기, 비타민d
 └──────────┘            160 ml  명란계란말이...

                        3월 19일 (목)
 ┌──────────┐
 │1일 17시간 │  06:16 PM ●── 이유식 소고기, 비타민d
 └──────────┘            160 ml  명란계란말이...

                        3월 18일 (수)
 ┌──────────┐
 │1일 1시간  │  05:16 PM ●── 이유식 소고기, 비타민d
 └──────────┘            160 ml  팽이버섯

                        3월 17일 (화)
 ┌──────────┐
 │23시간 11분│  06:05 PM ●── 이유식 소고기, 비타민d
 └──────────┘            160 ml  밥새우, 애호박, 당근, 계란...
```

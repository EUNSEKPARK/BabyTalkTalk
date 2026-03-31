# Design System: Midnight Nursery

## 1. Overview & Creative North Star
**Creative North Star: "The Ethereal Guardian"**
This design system moves away from the clinical, high-contrast look of traditional trackers. Instead, it embraces a "Digital Nocturne"—an experience that feels like a quiet, high-end nursery at 3:00 AM. We achieve this through a "Deep Glow" aesthetic: dark, velvety surfaces punctuated by soft, bioluminescent accents.

To break the "template" look, we utilize **Intentional Asymmetry**. Important metrics (like last feeding time) should not sit in a rigid grid; they should breathe within large, over-sized containers with varying corner radii, creating a layout that feels organic and "held" rather than boxed in.

---

## 2. Colors & Tonal Depth
The palette is rooted in deep nocturnal navies, using mint and gold not just as status indicators, but as light sources that "illuminate" the interface.

### The "No-Line" Rule
**Strict Mandate:** Prohibit the use of 1px solid borders for sectioning. Boundaries must be defined solely through background color shifts or subtle tonal transitions. 
*   *Implementation:* Use `surface_container_low` (#1A1A2E) for the general background and `surface_container` (#1E1E32) for primary cards. The eye should perceive change through depth, not lines.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of frosted glass.
*   **Base:** `surface_dim` (#111125)
*   **Sectioning:** `surface_container_low` (#1A1A2E)
*   **Interactive Cards:** `surface_container` (#1E1E32)
*   **Elevated Modals:** `surface_container_highest` (#333348)

### The "Glass & Gradient" Rule
To avoid a flat "Material" feel, use Glassmorphism for floating navigation bars and AI insights. 
*   **Formula:** `surface_container` at 60% opacity + 20px Backdrop Blur.
*   **Signature Textures:** For Primary CTAs, use a linear gradient from `primary` (#CCFFEB) to `primary_container` (#46F1C5) at a 135-degree angle. This adds a "soulful" glow that feels premium and intentional.

---

## 3. Typography
We utilize **Plus Jakarta Sans** (as a high-end alternative to Noto Sans KR for Latin characters) to provide a modern, geometric, yet friendly feel.

*   **Display (Display-LG/MD):** Used for "Hero" moments—like the baby's name or a "Time Since Last Fed" counter. These should use tight tracking (-2%) to feel editorial.
*   **Headlines (Headline-SM):** Used for card titles. These are the anchors of your layout.
*   **Body (Body-LG/MD):** Set in `on_surface` (#E2E0FC). The soft lavender tint reduces eye strain during night use compared to pure white.
*   **Labels (Label-SM):** Used for timestamps and metadata. Use `on_surface_variant` (#BACAC2) to create a clear information hierarchy.

---

## 4. Elevation & Depth
Depth is achieved through **Tonal Layering** rather than traditional drop shadows.

*   **The Layering Principle:** Place a `surface_container_lowest` (#0C0C20) card inside a `surface_container_low` (#1A1A2E) area to create a "recessed" look for historical data or logs.
*   **Ambient Shadows:** For floating elements (like an "Add Log" button), use a shadow with a 32px blur, 0px offset, and 8% opacity. The shadow color must be a tinted navy (from the `surface_container_lowest` palette), never pure black.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility, use `outline_variant` (#3B4A44) at **15% opacity**. It should be felt, not seen.

---

## 5. Components

### Buttons
*   **Primary:** Rounded `full` (9999px). Gradient background (`primary` to `primary_container`). Text color: `on_primary` (#00382B).
*   **Secondary (Sleep):** Background `secondary_container` (#464760). Text `secondary` (#C5C4E2).
*   **Tertiary (Health):** Background `tertiary_container` (#FFD268). Text `on_tertiary` (#3F2E00).

### Chips (Activity Tags)
Use `md` (1.5rem) roundedness. Use `surface_bright` (#37374D) for unselected states to maintain a "velvety" feel. Selected states should "glow" using the corresponding category color (Secondary for sleep, Tertiary for diaper).

### Input Fields
*   **Styling:** No bottom line. Use `surface_container_highest` (#333348) with a `lg` (2rem) corner radius. 
*   **Active State:** Instead of a border, use a 2px outer glow using `primary` at 30% opacity.

### Navigation Bar
Must be a floating "Island" using the **Glassmorphism** formula. Forbid the use of a divider line between the content and the nav bar. Use a 40px vertical margin from the bottom of the screen to make it feel like it's drifting.

### Cards & Lists
*   **Forbid Dividers:** Separate list items using `3.5` (1.2rem) of vertical whitespace.
*   **Asymmetric Radii:** For a signature look, try using `xl` (3rem) for the top-left and bottom-right corners, and `lg` (2rem) for the others.

---

## 6. Do’s and Don’ts

### Do
*   **Do** use wide margins (Spacing `8` or `10`) to create a sense of calm and luxury.
*   **Do** use the `primary` mint glow sparingly to draw the eye to AI-driven insights or "Next Action" reminders.
*   **Do** ensure all interactive elements have a minimum tap target of 48dp, keeping in mind tired parents with limited motor precision.

### Don’t
*   **Don't** use 100% white (#FFFFFF). It breaks the "Midnight" immersion and causes eye fatigue.
*   **Don't** use sharp corners. Nothing in this system should be less than `DEFAULT` (1rem) roundedness.
*   **Don't** use "Pop" animations. All transitions should be "Soft Fade" or "Slow Slide" (300ms-500ms) to match the cozy, nursery vibe.
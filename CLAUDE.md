# CLAUDE.md — Frontend Website Rules

## Always Do First
- **Invoke the `frontend-design` skill** before writing any frontend code, every session, no exceptions.

## Design Personality
This shop sells **stickers, magnets, pins, and bookmarks** — think cozy, handcrafted, and delightful.
The aesthetic is **soft, cute, and pink-forward**: gentle curves, playful type, pastel warmth, and a tactile feel.
Every page should feel like unwrapping something sweet. Not babyish — charming and intentional.

### Core Palette (use these, not Tailwind defaults)
| Role | Hex |
|---|---|
| Primary Pink | `#F2A7C3` |
| Soft Blush | `#FDE8F0` |
| Deep Rose (accents) | `#C1527A` |
| Cream Base | `#FFF8F5` |
| Warm Taupe (text) | `#4A3840` |
| Muted Mauve (secondary text) | `#9B7285` |

Adjust shades as needed, but always stay within the rose-pink-blush family. Never introduce cool blues, harsh grays, or default Tailwind palette colors.

### Typography
- **Headings:** A soft serif or rounded display font (e.g. *Playfair Display*, *DM Serif Display*, or *Fraunces*). Apply tight tracking (`-0.02em`) and gentle size scaling.
- **Body / UI:** A clean rounded sans-serif (e.g. *DM Sans*, *Plus Jakarta Sans*, or *Nunito*). Generous line-height (`1.75`).
- Never use the same font for headings and body text.
- Load via Google Fonts CDN.

### Signature Touches (apply to every build)
- **Rounded everything:** Use `rounded-2xl` or higher on cards, buttons, and images. Pill shapes (`rounded-full`) on badges and tags.
- **Soft shadows:** Layered, pink-tinted — e.g. `box-shadow: 0 4px 16px rgba(194, 82, 122, 0.12), 0 1px 4px rgba(194, 82, 122, 0.08)`. Never flat `shadow-md`.
- **Pastel gradients:** Background layers using radial or soft linear gradients in blush/cream. Add subtle SVG grain texture for a paper-like warmth.
- **Micro-details:** Sprinkle decorative elements — tiny stars ✦, hearts ♡, dots, or soft botanical SVGs — as section dividers or accent marks.
- **Product cards:** Always show product image prominently with a blush or cream card background. Include a soft hover lift (`transform: translateY(-4px)`) with transition on `transform` and `opacity` only.
- **Buttons:** Rounded-full, rose-tinted with soft shadow. Hover state brightens fill and lifts slightly. Active state presses down (`scale(0.97)`).
- **Badges / tags:** Pill-shaped, pastel-filled (blush or lavender-pink), small and cute — used for product categories, "new," "limited," etc.

## Reference Images
- If a reference image is provided: match layout, spacing, typography, and color exactly. Swap in placeholder content (`https://placehold.co/` for images, generic copy). Do not improve or add to the design.
- If no reference image: design from scratch with the cute-pink brand aesthetic and high craft (see guardrails below).
- Screenshot your output, compare against reference, fix mismatches, re-screenshot. Do at least 2 comparison rounds. Stop only when no visible differences remain or the user says so.

## Local Server
- **Always serve on localhost** — never screenshot a `file:///` URL.
- Start the dev server: `node serve.mjs` (serves the project root at `http://localhost:3000`)
- `serve.mjs` lives in the project root. Start it in the background before taking any screenshots.
- If the server is already running, do not start a second instance.

## Screenshot Workflow
- Puppeteer is installed at `C:/Users/nateh/AppData/Local/Temp/puppeteer-test/`. Chrome cache is at `C:/Users/nateh/.cache/puppeteer/`.
- **Always screenshot from localhost:** `node screenshot.mjs http://localhost:3000`
- Screenshots are saved automatically to `./temporary screenshots/screenshot-N.png` (auto-incremented, never overwritten).
- Optional label suffix: `node screenshot.mjs http://localhost:3000 label` → saves as `screenshot-N-label.png`
- `screenshot.mjs` lives in the project root. Use it as-is.
- After screenshotting, read the PNG from `temporary screenshots/` with the Read tool — Claude can see and analyze the image directly.
- When comparing, be specific: "heading is 32px but reference shows ~24px", "card gap is 16px but should be 24px"
- Check: spacing/padding, font size/weight/line-height, colors (exact hex), alignment, border-radius, shadows, image sizing

## Output Defaults
- Single `index.html` file, all styles inline, unless user says otherwise
- Tailwind CSS via CDN: `<script src="https://cdn.tailwindcss.com"></script>` with custom config for brand colors
- Placeholder images: `https://placehold.co/WIDTHxHEIGHT/FDE8F0/C1527A` (blush bg, rose text — on-brand placeholders)
- Mobile-first responsive
- Google Fonts loaded in `<head>` for chosen font pair

## Brand Assets
- Always check the `brand_assets/` folder before designing. It may contain logos, color guides, style guides, or images.
- If assets exist there, use them. Do not use placeholders where real assets are available.
- If a logo is present, use it. If a color palette is defined, use those exact values — do not invent brand colors outside of it.

## Shop-Specific Conventions
- **Product showcase sections:** Grid layout (2-col mobile, 3–4 col desktop). Cards with rounded corners, subtle blush background, product name in display font, price in deep rose, add-to-cart or "view" button in pill shape.
- **Hero sections:** Warm cream/blush gradient background. Large soft-serif headline. Optional floating product cutouts or decorative sticker-style illustrations.
- **Category navigation:** Pill-shaped filter tabs in pastel shades. Active state fills with primary pink.
- **Testimonials / showcase:** Soft card grid with quote marks styled in large, light rose. Customer name in mauve.
- **Footer:** Keep it cozy — match the blush palette, include social links styled as soft icon buttons.
- **Empty states / loading:** Use on-brand placeholder text and a small decorative heart or star element — never a generic spinner.

## Anti-Generic Guardrails
- **Colors:** Always stay in the rose-pink-blush-cream family. No default Tailwind indigo, blue, or gray as primary colors.
- **Shadows:** Always pink-tinted and layered. No flat `shadow-md`.
- **Typography:** Always pair display serif + rounded sans. Never same font for headings and body.
- **Gradients:** Soft radial blushes layered on cream. Add SVG grain/noise filter for paper texture warmth.
- **Animations:** Only animate `transform` and `opacity`. Never `transition-all`. Use gentle spring-style easing (`cubic-bezier(0.34, 1.56, 0.64, 1)` for lifts).
- **Interactive states:** Every clickable element needs hover, focus-visible, and active states. No exceptions.
- **Images:** Use a soft gradient overlay where needed. For product images, keep backgrounds clean (cream or blush) so products pop.
- **Spacing:** Consistent, intentional spacing tokens. Sections should breathe — generous padding, not cramped.
- **Depth:** Base (cream) → elevated (white card) → floating (modal/tooltip) layering system. Surfaces are not flat.
- **Cuteness factor:** When in doubt, round it more, soften it more, add one small decorative detail. The shop should feel handmade and warm.

## Hard Rules
- Do not add sections, features, or content not in the reference
- Do not "improve" a reference design — match it
- Do not stop after one screenshot pass
- Do not use `transition-all`
- Do not use default Tailwind blue/indigo as primary color
- Do not use cold, sterile, or corporate-feeling design choices
- Do not use sharp corners where rounded ones are possible

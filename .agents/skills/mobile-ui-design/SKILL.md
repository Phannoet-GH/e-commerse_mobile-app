---
name: mobile-ui-design
description: Comprehensive modern mobile e-commerce design system & UX skill covering Material 3, frosted glassmorphism, dynamic capsule navigators, micro-interactions, fluid spring physics, and luxury retail aesthetics.
---

# Modern Mobile E-Commerce Design System & UX Standards

This skill provides the comprehensive architectural patterns, visual tokens, ergonomics, and micro-interaction specifications for building modern mobile e-commerce applications (inspired by SSENSE, Apple Store, Farfetch, and Nike).

---

## 1. Design Philosophy: Modern Luxury Retail

1. **Content-First Visual Hierarchy**:
   - Product imagery takes center stage with clean `0.68 - 0.72` portrait aspect ratios and subtle neutral backgrounds (`#F8F9FA` in light, `#0F172A` / `#000000` in OLED dark).
   - Low visual noise: border outlines are subtle (`1px` with `0.06 - 0.12` opacity), shadows are diffuse (`0 10px 30px rgba(0,0,0,0.06)`).

2. **Depth & Glassmorphism**:
   - Floating navigation surfaces utilize `BackdropFilter` with `15px - 25px` Gaussian blur, paired with subtle top highlight borders (`rgba(255,255,255,0.15)`).

3. **Fluid Micro-Interactions & Spring Physics**:
   - Bouncy heart icon toggles with scale punch (`1.0 -> 1.35 -> 1.0`).
   - Sticky bottom action bars on product details (`Add to Cart` + `Buy Now`) pinned above safe-area insets.
   - Expanding capsule navigation tabs with `AnimatedCrossFade` and `Curves.easeOutCubic`.

---

## 2. Master Color System & Semantic Tokens

```
Token                Light Value         Dark Value          Usage
-------------------------------------------------------------------------------------------------
Primary Accent       #FF2D6F (Neon Pink) #FF3B7D             High-intent CTAs, active capsules, flash sales
Dark Surface         #1E1E2F (Onyx)      #111827             Headers, pill bars, high-contrast badges
Background Base      #F8FAFC (Slate-50)  #0B0F19 (Deep Dark) App scaffold body
Card Surface         #FFFFFF             #151C2C             Elevated cards, product tiles, dialogs
Success / In-Stock   #10B981 (Emerald)   #34D399             Free shipping, confirmed orders, inventory
Warning / Stars      #F59E0B (Amber)     #FBBF24             Star ratings, limited stock alerts
Border Subtle        rgba(0,0,0,0.06)    rgba(255,255,255,0.08) Section dividers, tile outlines
```

---

## 3. Mobile Touch Ergonomics & Safe Areas

- **Minimum Tap Target**: `48 x 48 dp` for all touchable icons and buttons.
- **Thumb Zone Optimization**: Primary conversion buttons (Checkout, Add to Cart, Filter Apply) placed in the lower 35% of the screen.
- **Scroll Padding**: All scroll views (`ListView`, `GridView`, `SingleChildScrollView`) MUST include bottom padding of at least `110dp` to prevent the floating capsule bar from clipping bottom items.
- **Haptics Integration**:
  - `HapticFeedback.selectionClick()` on chip taps, size selectors, and tab switches.
  - `HapticFeedback.mediumImpact()` on adding to cart or order submission.

---

## 4. Key Component Blueprints

### A. Expanding Capsule Floating Nav Bar
- Floating container elevated `16dp` above bottom screen edge.
- Frosted glass background with `BorderRadius.circular(36)`.
- Active tab smoothly expands to show icon + text badge, inactive tabs display compact icon.

### B. 4-Stage Multi-Step Checkout Stepper
- Visual progress path: `[1. Address] ── [2. Delivery] ── [3. Payment] ── [4. Review]`.
- Completed steps display a green checkmark `✓`, active step glows with primary accent ring.

### C. Free Shipping Live Threshold Progress Bar
- Dynamic calculation towards threshold (e.g. `$100.00`).
- Progress fill with animated gradient (`#FF2D6F` $\rightarrow$ `#10B981`).
- Dynamic status message (`"Add $XX.XX more for Free Shipping"` $\rightarrow$ `"🎉 Free Express Shipping Unlocked!"`).

### D. Live Order Milestone Tracker
- Vertical or horizontal 4-stage tracking timeline:
  1. *Order Placed*
  2. *Processing & Packing* (Active / Pulsing beacon)
  3. *Shipped & Out for Delivery*
  4. *Delivered to Doorstep*
- Courier dispatch card with direct call action.

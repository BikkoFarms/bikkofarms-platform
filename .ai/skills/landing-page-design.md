# Skill Manual: Landing Page Design

Guidelines for implementing the BikkoChain public-facing marketing website.

---

## 🎯 Purpose

The public landing page is the first impression for investors, cooperatives, and farmer representatives. It must communicate BikkoChain's value proposition instantly, drive co-op portal sign-ups, and provide farmers with USSD/WhatsApp access instructions.

---

## 🎨 Visual Identity

- **Theme:** Modern, organic, premium agri-fintech
- **Primary:** Rich Forest Green `hsl(125, 35%, 18%)` + `hsl(125, 35%, 25%)`
- **Accent:** Golden Amber `hsl(43, 65%, 52%)` + `hsl(43, 65%, 40%)`
- **Background (light):** Soft cream `hsl(50, 20%, 97%)`
- **Background (dark):** Deep graphite `hsl(127, 10%, 8%)`
- **Aesthetics:** Glassmorphism cards, scroll-triggered animations, SVG agricultural illustrations
- **Typography:**
  - Headings: Playfair Display (serif, premium feel)
  - Body: Inter (sans-serif, readable)
  - Load via `next/font/google`

---

## 📂 Component Hierarchy

```
src/app/
└── (landing)/
    ├── page.tsx                  # Main page layout
    ├── layout.tsx                # Header/Footer wrapper
    └── _components/
        ├── Header.tsx            # Nav + CTA "Access Portal"
        ├── Hero.tsx              # Headline + CTAs + background graphic
        ├── ProblemSection.tsx    # 3 pain points in split grid
        ├── SolutionSection.tsx   # 3 feature highlights with icons
        ├── HowItWorks.tsx        # Vertical step timeline
        ├── FeaturesGrid.tsx      # USSD / WhatsApp / Lisk / Kotani cards
        ├── BenefitsSection.tsx   # Farmers / Co-ops / Liquidity Providers
        ├── FAQAccordion.tsx      # Radix-based expandable FAQ
        ├── CTASection.tsx        # "Ready to grow?" full-width banner
        └── Footer.tsx            # Links, social, Lisk ecosystem badge
```

---

## 📋 Section Content Requirements

### Hero
- Heading (h1): `"Collateralize Your Harvest, Secure Your Future."`
- Sub-heading: `"Instant agricultural loans for smallholder cocoa and coffee farmers in Ghana, powered by the Lisk blockchain."`
- CTA Primary: `"Apply via USSD: *713*77#"` or `"Apply on WhatsApp"`
- CTA Secondary: `"Explore Co-op Portal"`

### How It Works (5 Steps)
1. Register with your local cooperative
2. Cooperative inspects and mints your digital harvest certificate
3. Certificate locked in BikkoChain smart contract as collateral
4. Funds deposited to your MTN MoMo / AirtelTigo wallet instantly
5. Harvest proceeds settle the loan — release the token surplus to you

### Key Features (4 Cards)
- USSD-Friendly: No smartphone needed — `*713*77#`
- WhatsApp Assistance: Message-based loan applications
- Lisk L2: Transactions < $0.01, sub-second confirmations
- Kotani Pay: Direct GHS mobile money transfers

---

## 📐 Code Conventions

- **RSC by default:** All landing page components are React Server Components unless they use scroll events or animations
- **Client components:** Only `Header.tsx` (mobile menu state) and `FAQAccordion.tsx` (open/close state) need `"use client"`
- **Animations:** Use `@keyframes` CSS animations triggered by `IntersectionObserver` — no heavy JS animation libraries
- **Images:** Use `next/image` with `priority` on Hero image. Use WebP format for all agricultural illustrations.

---

## 🔍 SEO

```tsx
// app/(landing)/layout.tsx
export const metadata = {
  title: 'BikkoChain | Instant Agricultural Loans for Farmers in Ghana',
  description: 'Access near-instant, low-interest agricultural loans using tokenized future cocoa and coffee harvests. Powered by Lisk blockchain and Kotani Pay mobile money.',
  keywords: ['agritech loans Ghana', 'tokenized harvest collateral', 'Lisk crop tokenization', 'Kotani Pay mobile money'],
  openGraph: {
    title: 'BikkoChain | Agricultural Micro-Lending',
    description: 'Blockchain-powered micro-loans for Ghana\'s cocoa and coffee farmers.',
    type: 'website',
  },
};
```

- Exactly one `<h1>` (in Hero section)
- `<section>` tags for each major section with `aria-label`
- Structured data (JSON-LD): `FinancialService` + `Organization` schemas

---

## ⚠️ Common Pitfalls

- **Over-animating:** Excessive motion causes accessibility issues. Respect `prefers-reduced-motion` media query.
- **Missing loading states:** Hero image should have a placeholder blur while loading.
- **Blocking fonts:** Use `next/font/google` with `display: 'swap'` to prevent FOIT.

---

## ✅ Acceptance Criteria

1. Lighthouse Performance: 90+ desktop, 85+ mobile
2. Lighthouse Accessibility: 95+
3. Core Web Vitals: LCP < 2.5s, CLS < 0.1, FID < 100ms
4. Single `<h1>` per page, proper heading hierarchy
5. All images have descriptive `alt` text
6. Mobile menu works on 320px+ screens

# Quality Checklist: Frontend

Required checks before merging UI adjustments or landing page sections.

---

## 📱 Responsive Layout Checks
- [ ] UI elements fluidly adapt from 320px to 1920px screen widths.
- [ ] No horizontal scrollbars appear on standard mobile viewports (width < 768px).
- [ ] Click target elements (buttons, links) are at least 44x44px on mobile viewports.
- [ ] Dynamic forms and text columns wrap without clipping.

---

## ⚡ Lighthouse Targets
- [ ] **Performance:** 85+ (Mobile) / 90+ (Desktop)
- [ ] **Accessibility:** 95+
- [ ] **Best Practices:** 90+
- [ ] **SEO:** 90+

---

## ♿ Accessibility Checks
- [ ] Dialog components implement keyboard trap mechanics correctly.
- [ ] Form input tags are linked directly to text label elements.
- [ ] Visual elements (icons) have `aria-hidden="true"`, and button icons define `aria-label` text.
- [ ] Text elements have appropriate contrast ratios.

---

## 🔍 SEO Best Practices
- [ ] Every page sets unique, descriptive title tags.
- [ ] Compelling meta descriptions are declared within index routing headers.
- [ ] Semantic HTML headings follow a clean hierarchical tree (`h1` -> `h2` -> `h3`).
- [ ] Open Graph (OG) social card elements are configured for sharing previews.

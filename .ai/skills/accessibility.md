# Skill Manual: Accessibility (a11y)

Guidelines and conventions for building interfaces compliant with WCAG 2.1 AA standards.

---

## 🎯 Purpose
Ensure all BikkoChain web components, portals, and applications are inclusive and navigable for all users, including those with visual, motor, cognitive, or auditory impairments.

---

## 💡 Best Practices

* **Semantic HTML:** Use native elements (like `<button>`, `<input>`, `<nav>`, `<aside>`) instead of nested `<div>`s with event handlers. Native elements have built-in keyboard accessibility and screen-reader roles.
* **Color Contrast:** Keep color contrast ratios above WCAG requirements:
  * Minimum 4.5:1 for normal text.
  * Minimum 3:1 for large text (18pt/24px or bold 14pt/18.6px).
* **Keyboard Navigable:** Ensure all interactive elements can be focused and triggered using only the Tab and Enter/Space keys. Maintain a logical tab order.
* **Radix/shadcn Primitives:** Leverage UI primitives from Radix (packaged inside shadcn) which automatically handle keyboard traps, aria-attributes, and state transitions.

---

## 🛑 Constraints

* **No Focus Ring Removal:** Never remove default focus rings without replacing them with clear custom outlines (`focus-visible:ring-2`).
* **Alt Attributes Required:** All descriptive images must have descriptive `alt` tags. Non-descriptive/purely visual icons must be marked with `aria-hidden="true"`.
* **No Text-In-Image:** Never overlay critical informational text inside raw image assets. Render it as CSS-styled text overlay.

---

## 📐 Code Conventions

* **Aria Attributes for Custom Components:**
  ```tsx
  // Example of using Radix dialog components to maintain accessible modals
  import * as Dialog from '@radix-ui/react-dialog';
  
  export const AccessibleModal = () => (
    <Dialog.Root>
      <Dialog.Trigger asChild>
        <button className="btn">Open Details</button>
      </Dialog.Trigger>
      <Dialog.Portal>
        <Dialog.Overlay className="dialog-overlay" />
        <Dialog.Content className="dialog-content">
          <Dialog.Title>Loan Agreement Terms</Dialog.Title>
          <Dialog.Description>Please read carefully before signing.</Dialog.Description>
          {/* Content */}
          <Dialog.Close asChild>
            <button aria-label="Close modal">Close</button>
          </Dialog.Close>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
  ```
* **Explicit Inputs Labels:** Always connect `<label>` elements explicitly to inputs using the `htmlFor` attribute.

---

## ⚠️ Common Pitfalls

* **Dynamic Modals Keyboard Traps:** Users navigating with Tab keys getting locked in background layers when a modal overlay opens.
* **Icon Buttons without Screen Reader Text:** Placing a pen icon for edit without specifying an `aria-label="Edit harvest report"`.
* **Color-Only State Cues:** Indication of error or success using red or green colors exclusively. Provide text descriptions or specific icons.

---

## ✅ Acceptance Criteria

1. **Lighthouse Accessibility Score:** 95+ on all web pages.
2. **Keyboard Testing:** Entire application can be navigated, submitted, and canceled without a mouse.
3. **Screen Reader Verification:** All descriptive details are properly read out without redundant alerts.

# Pull Request Template

## 📝 Description
Provide a concise summary of the changes introduced by this pull request. If it fixes a bug, link the corresponding issue here (e.g. `Fixes #123`).

## 🧱 Key Technical Changes
* List major shifts in code structure, DB models, or smart contracts.

## 🧪 Testing Evidence
Detail the manual and automated validation tests executed. Include screenshots, transaction hashes, or console test logs.

```bash
# Paste test outputs here
```

## 📸 Screenshots or UI Demos
If this PR includes frontend or layout changes, attach screenshots/screencasts showing the mobile, tablet, and desktop views.

---

## ✅ Pull Request Checklist

Please ensure all items are checked before requesting a review:

- [ ] **Branch naming convention:** Name matches `feature/*`, `fix/*`, `chore/*`, or `docs/*`.
- [ ] **Commit message conventions:** Follows Conventional Commits (`feat: `, `fix: `, `docs: `, `refactor: `, `test: `, `chore: `).
- [ ] **Type safety:** Strict TypeScript passes with zero compiler warnings and zero `any` declarations.
- [ ] **Testing:** All unit and integration tests run successfully and coverage targets are satisfied.
- [ ] **Security:** Checked inputs sanitization, role permissions, and validated secrets scanner output.
- [ ] **a11y & SEO:** UI layout conforms to WCAG 2.1 AA contrast/keyboard standards and sets SEO descriptors.
- [ ] **Documentation:** System architecture documents and inline comments are updated.

# Quality Checklist: Documentation

Required documentation tasks before merging code.

---

## 📐 Code Annotations & Inline Docs
- [ ] Exported functions, utilities, and components declare explicit TypeScript JSDoc comments.
- [ ] Complex algorithms or business rules (such as interest mechanics or weather oracle triggers) feature inline comments explaining *why* a particular pattern is chosen.

## 📂 System Design & Diagrams
- [ ] Architecture design specs in `/docs/` updated to reflect changes in routing, data structures, or server interactions.
- [ ] Schema changes in the database are reflected in the database documentation model.

## 📡 API Documents
- [ ] API routes match corresponding Swagger/OpenAPI schemas.
- [ ] Example request/response shapes are provided for new webhook paths.

## 🤖 AI OS Sync
- [ ] If new developer rules are agreed, `.ai/rules/agent-rules.md` is updated.
- [ ] Relevant specialized agent files (.ai/agents/*) or skills (.ai/skills/*) are modified to capture new conventions.
